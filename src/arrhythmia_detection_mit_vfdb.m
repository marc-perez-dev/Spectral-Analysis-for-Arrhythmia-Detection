%% Ejercicio 3: Base de datos de arritmias ventriculares malignas (MIT)
clc; clear; close all;
addpath(fullfile('..', 'lib'));

%% --- CONFIGURACIÓN DE HIPERPARÁMETROS ---
usar_dos_derivaciones = true; % Clustering 18D con Bautizo 9D
filtrar = true;             % Aplicar filtrado previo a la señal
vent_pwelch_s = 2;          % Longitud de la ventana de Welch en segundos
umbral_factor = 1.2;        % Factor de tolerancia para el Umbral de Rechazo
k_clusters = 12;             % Número de clusters para K-Means
k_replicates = 50;           % Replicaciones para evitar mínimos locales en K-Means
k_distance = 'sqeuclidean'; % Métrica de distancia para K-Means

% Cargamos siempre el modelo de 1 derivación (el ancla)
modelo_nombre = fullfile('..', 'models', 'modelo_referencia_1Lead.mat');
%% ----------------------------------------

% Directorio de los datos
mit_dir = fullfile('..', 'data', 'MIT - VFDB');

% Paso 1: Segmentos de interés
registros(1).id = '418'; registros(1).segmentos = {[0, 20], [399, 406], [-1, 20]};
registros(2).id = '419'; registros(2).segmentos = {[0, 20], [320, 340], [1320, 1400], [-1, 100]};
registros(3).id = '420'; registros(3).segmentos = {[1632, 1672]};
registros(4).id = '421'; registros(4).segmentos = {[1420, 1440]};
registros(5).id = '422'; registros(5).segmentos = {[1960, 1980]};
registros(6).id = '423'; registros(6).segmentos = {[0, 20], [960, 980], [-1, 20]};
registros(7).id = '424'; registros(7).segmentos = {[1280, 1320]};
registros(8).id = '425'; registros(8).segmentos = {[1408, 1428], [1440, 1500]};
registros(9).id = '426'; registros(9).segmentos = {[1872, 1900]};
registros(10).id = '427'; registros(10).segmentos = {[1084, 1116]};

base_datos_segmentos = struct('id_registro', {}, 'id_segmento', {}, 'ecg', {}, 'fs', {});
indice_db = 1;

for i = 1:length(registros)
    id = registros(i).id;
    fpath = fullfile(mit_dir, [id '.dat']);
    try datos = leedatos(fpath); catch, continue; end
    fs = datos.fs;
    N_total = size(datos.ECG, 2);
    for j = 1:length(registros(i).segmentos)
        seg = registros(i).segmentos{j};
        if seg(1) == -1
            idx_fin = N_total; idx_inicio = N_total - round(seg(2)*fs) + 1;
        else
            idx_inicio = round(seg(1)*fs) + 1; idx_fin = round(seg(2)*fs);
        end
        ecg_recorte = datos.ECG(:, max(1, idx_inicio):min(N_total, idx_fin));
        base_datos_segmentos(indice_db).id_registro = id;
        base_datos_segmentos(indice_db).id_segmento = j;
        base_datos_segmentos(indice_db).ecg = ecg_recorte;
        base_datos_segmentos(indice_db).fs = fs;
        indice_db = indice_db + 1;
    end
end

%% PASO 6: Extracción a Dos Bandas
num_segmentos = length(base_datos_segmentos);
feat_L1 = zeros(num_segmentos, 9);
feat_L2 = zeros(num_segmentos, 9);
nombres_segmentos = cell(num_segmentos, 1);
espectros_mit = cell(num_segmentos, 1);
frecuencias_mit = cell(num_segmentos, 1);

for i = 1:num_segmentos
    ecg_total = base_datos_segmentos(i).ecg;
    fs = base_datos_segmentos(i).fs;
    nombres_segmentos{i} = sprintf('%s_S%d', base_datos_segmentos(i).id_registro, base_datos_segmentos(i).id_segmento);
    
    % Derivación 1
    sig1 = ecg_total(1,:);
    if filtrar, sig1 = FiltrarSenyal_Espectro(sig1, fs); else, sig1 = sig1 - mean(sig1); end
    [pxx1, f1] = pwelch(sig1, hamming(round(vent_pwelch_s*fs)), [], [], fs);
    feat_L1(i, :) = extraer_caracteristicas(pxx1, f1);
    espectros_mit{i} = pxx1; frecuencias_mit{i} = f1;

    % Derivación 2
    if usar_dos_derivaciones && size(ecg_total, 1) >= 2
        sig2 = ecg_total(2,:);
        if filtrar, sig2 = FiltrarSenyal_Espectro(sig2, fs); else, sig2 = sig2 - mean(sig2); end
        [pxx2, f2] = pwelch(sig2, hamming(round(vent_pwelch_s*fs)), [], [], fs);
        feat_L2(i, :) = extraer_caracteristicas(pxx2, f2);
    end
end

%% PASO 8: Normalización Híbrida y Clasificación
if exist(modelo_nombre, 'file')
    load(modelo_nombre, 'media_ej2', 'std_ej2', 'centroides', 'clases_unicas', 'vector_caract_norm', 'etiquetas');
else
    error('Ejecuta primero feature_extraction_reference_model.m');
end

% L1: Normalización con Referencia (9D)
L1_norm_mit = (feat_L1 - media_ej2) ./ std_ej2;

% L2: Normalización Interna (Z-score) si aplica
if usar_dos_derivaciones
    L2_norm_mit = zscore(feat_L2);
    matriz_clustering = [L1_norm_mit, L2_norm_mit]; % 18D
else
    matriz_clustering = L1_norm_mit; % 9D
end

% Umbral de Rechazo (siempre sobre L1 para ser coherentes con el modelo)
distancias_intra = zeros(size(vector_caract_norm, 1), 1);
for i = 1:length(etiquetas)
    idx_c = find(strcmp(clases_unicas, etiquetas{i}));
    if ~isempty(idx_c)
        distancias_intra(i) = sqrt(sum((vector_caract_norm(i,:) - centroides(idx_c,:)).^2));
    end
end
Umbral_Rechazo = max(distancias_intra) * umbral_factor;

% Clasificación Template Matching (usando solo L1)
predicciones = cell(num_segmentos, 1);
for i = 1:num_segmentos
    dists = sqrt(sum((L1_norm_mit(i,:) - centroides).^2, 2));
    [min_d, idx_c] = min(dists);
    if min_d > Umbral_Rechazo, predicciones{i} = 'Otro'; else, predicciones{i} = clases_unicas{idx_c}; end
end

%% K-MEANS POTENCIADO Y BAUTIZO TRUNCADO
[idx_clusters, nuevos_centroides] = kmeans(matriz_clustering, k_clusters, 'Replicates', k_replicates);

etiquetas_clusters = cell(k_clusters, 1);
for j = 1:k_clusters
    centroide_k_completo = nuevos_centroides(j, :);
    % PROYECCIÓN PARCIAL: Usamos solo las primeras 9 columnas (L1) para bautizar
    centroide_k_L1 = centroide_k_completo(1:9);
    
    dists_ref = sqrt(sum((centroide_k_L1 - centroides).^2, 2));
    [min_d, idx_r] = min(dists_ref);
    if min_d > Umbral_Rechazo, etiquetas_clusters{j} = 'Otro'; else, etiquetas_clusters{j} = clases_unicas{idx_r}; end
    fprintf('Cluster %d -> %s (Dist L1: %.4f)\n', j, etiquetas_clusters{j}, min_d);
end

predicciones_kmeans = etiquetas_clusters(idx_clusters);

%% PASO 9: Resultados y Comprobación Clínica (Sanity Check)

% Definición de nombres para las gráficas (L1)
nombres_caract_L1 = {'Frec. Pico', 'Ancho Pico', 'Num. Armon', 'Skewness', 'Kurtosis', 'Centroid', 'Pot. Total', 'Pot. Pico', 'Ratio PP/PT'};

% Selección de las 2 mejores características de L1 (usando los datos de Ejercicio 2)
p_vals = zeros(9, 1);
for k = 1:9
    p_vals(k) = kruskalwallis(vector_caract_norm(:, k), etiquetas, 'off');
end
[~, idx_best] = sort(p_vals);
idx1 = idx_best(1);
idx2 = idx_best(2);

% Cálculo de métrica de consenso
coincidencias = strcmp(predicciones, predicciones_kmeans);
porcentaje_consenso = (sum(coincidencias) / num_segmentos) * 100;
fprintf('\nMétrica de Consenso: %.2f%% de coincidencia entre métodos.\n', porcentaje_consenso);

T = table(predicciones, predicciones_kmeans, 'VariableNames', {'Template_L1', 'KMeans_Dual'}, 'RowNames', nombres_segmentos);
disp('--- COMPARATIVA DE CLASIFICACIÓN (MIT-VFDB) ---');
disp(T);

% 1. Visualización: Espacio de Características (Template Matching L1)
figure('Name', 'Clasificación MIT-VFDB: Template Matching (L1)');
gscatter(L1_norm_mit(:,idx1), L1_norm_mit(:,idx2), predicciones, 'rgbk', 'osd*');
hold on;
plot(centroides(:,idx1), centroides(:,idx2), 'kx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Centroides Ref');
xlabel(nombres_caract_L1{idx1}); ylabel(nombres_caract_L1{idx2});
title('Template Matching (Basado solo en L1)'); grid on; legend('Location', 'northeastoutside');

% 2. Visualización: Espacio de Características (K-Means Dual Proyectado a L1)
figure('Name', 'Clasificación MIT-VFDB: K-Means Dual (Proyección L1)');
gscatter(matriz_clustering(:,idx1), matriz_clustering(:,idx2), predicciones_kmeans, 'rgbk', 'osd*');
hold on;
% Proyectamos los centroides de 18D a las dimensiones idx1 e idx2 de L1
plot(nuevos_centroides(:,idx1), nuevos_centroides(:,idx2), 'm+', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Centr. KM (Proj L1)');
plot(centroides(:,idx1), centroides(:,idx2), 'kx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Centroides Ref');
xlabel(nombres_caract_L1{idx1}); ylabel(nombres_caract_L1{idx2});
title('K-Means Dual (Clustering 18D -> Proyección L1)'); grid on; legend('Location', 'northeastoutside');

% 3. Visualización: Comprobación Clínica (Espectros L1 agrupados por K-Means)
figure('Name', 'K-Means Dual: DEP L1 por Clase Predicha');
clases_plot = [clases_unicas, {'Otro'}];
colores = {'r', 'g', 'b', 'k'};

for c = 1:length(clases_plot)
    ax = subplot(length(clases_plot), 1, c);
    hold on; grid on;
    title(['K-Means Dual: ', clases_plot{c}], 'FontWeight', 'bold');
    ylabel('DEP');
    
    idx_pred_km = strcmp(predicciones_kmeans, clases_plot{c});
    if any(idx_pred_km)
        segmentos_clase = find(idx_pred_km);
        for s = segmentos_clase'
            plot(ax, frecuencias_mit{s}, espectros_mit{s}, 'Color', colores{c});
        end
    else
        text(0.5, 0.5, 'Sin segmentos', 'HorizontalAlignment', 'center');
    end
    xlim([0 10]);
    if c == length(clases_plot), xlabel('Frecuencia (Hz)'); end
end

%% PASO 10: GUARDADO AUTOMÁTICO DEL EXPERIMENTO
carpeta_res = fullfile('..', 'Resultados_Experimentos'); if ~exist(carpeta_res, 'dir'), mkdir(carpeta_res); end

% Construcción de nombre descriptivo (Leads, Filtrado, K-Clusters, Consenso, Timestamp)
str_leads = '1L'; if usar_dos_derivaciones, str_leads = '2L'; end
str_filt = 'Filt'; if ~filtrar, str_filt = 'NoFilt'; end
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

nombre_base = sprintf('Exp_%s_%s_K%d_C%.0f_%s', ...
    str_leads, str_filt, k_clusters, porcentaje_consenso, timestamp);

% Empaquetar todo en una estructura de experimento
experimento.config.usar_dos_derivaciones = usar_dos_derivaciones;
experimento.config.filtrar = filtrar;
experimento.config.vent_pwelch_s = vent_pwelch_s;
experimento.config.umbral_factor = umbral_factor;
experimento.config.k_clusters = k_clusters;
experimento.config.k_replicates = k_replicates;
experimento.config.k_distance = k_distance;

experimento.resultados.tabla = T;
experimento.resultados.consenso = porcentaje_consenso;
experimento.resultados.umbral_calculado = Umbral_Rechazo;
experimento.resultados.predicciones_tm = predicciones;
experimento.resultados.predicciones_km = predicciones_kmeans;

experimento.modelo.centroides_km = nuevos_centroides;
experimento.modelo.bautizo_clusters = etiquetas_clusters;
experimento.modelo.indices_caract = [idx1, idx2];
experimento.modelo.nombres_caract = {nombres_caract_L1{idx1}, nombres_caract_L1{idx2}};

experimento.datos.vector_norm = matriz_clustering; % Contendrá 9 o 18 columnas según la config
experimento.datos.nombres_segmentos = nombres_segmentos;
experimento.datos.espectros = espectros_mit;
experimento.datos.frecuencias = frecuencias_mit;

save(fullfile(carpeta_res, [nombre_base '.mat']), 'experimento');
fprintf('Datos guardados en: %s.mat\n', nombre_base);
fprintf('--- EXPERIMENTO FINALIZADO ---\n');
