%% SCRIPT DE VISUALIZACIÓN DE EXPERIMENTOS GUARDADOS
% clc; clear; close all;
addpath(fullfile('..', 'lib'));

% 1. Seleccionar el archivo del experimento
carpeta_res = fullfile('..', 'Resultados_Experimentos');
if ~exist(carpeta_res, 'dir')
    error('No existe la carpeta de resultados "Resultados_Experimentos".');
end

[file, path] = uigetfile(fullfile(carpeta_res, '*.mat'), 'Selecciona un experimento guardado');

if isequal(file, 0)
    disp('Operación cancelada por el usuario.');
    return;
end

% 2. Cargar datos
load(fullfile(path, file), 'experimento');
fprintf('Cargando experimento: %s\n', file);

% 3. Cargar el modelo de referencia para los centroides originales (necesario para las gráficas)
if exist(fullfile('..', 'models', 'modelo_referencia_1Lead.mat'), 'file')
    load(fullfile('..', 'models', 'modelo_referencia_1Lead.mat'), 'centroides', 'clases_unicas');
elseif exist(fullfile('..', 'models', 'modelo_referencia.mat'), 'file')
    load(fullfile('..', 'models', 'modelo_referencia.mat'), 'centroides', 'clases_unicas');
else
    error('No se encuentra el modelo de referencia en la carpeta "models" del nivel superior.');
end

% Extraer variables para facilitar el código
cfg = experimento.config;
res = experimento.resultados;
mod = experimento.modelo;
dat = experimento.datos;

idx1 = mod.indices_caract(1);
idx2 = mod.indices_caract(2);
nombres_caract_full = {'Frecuencia Pico', 'Ancho Pico', 'Num Armónicos', 'Skewness', 'Kurtosis', 'Centroide Espectral', 'Potencia Máxima', 'Ratio PP/PT', 'Frecuencia 75% Pot'};

% 4. Mostrar Resultados en Consola
disp('--- CONFIGURACIÓN DEL EXPERIMENTO ---');
disp(struct2table(cfg));
fprintf('\n--- MÉTRICA DE CONSENSO: %.2f%% ---\n', res.consenso);
disp('--- TABLA DE CLASIFICACIÓN ---');
disp(res.tabla);

% 5. Recrear Visualización 1: Template Matching
figure('Name', ['Visualizador: Template Matching - ' file]);
% Usamos dat.vector_norm, sabiendo que las primeras 9 columnas son L1
gscatter(dat.vector_norm(:,idx1), dat.vector_norm(:,idx2), res.predicciones_tm, 'rgbk', 'osd*');
hold on;
plot(centroides(:,idx1), centroides(:,idx2), 'kx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Centroides Ref');
xlabel(sprintf('%d. %s (Z-score)', idx1, nombres_caract_full{idx1}));
ylabel(sprintf('%d. %s (Z-score)', idx2, nombres_caract_full{idx2}));
title(sprintf('Clasificación con Umbral de Rechazo (TM)\nFactor Umbral: %.1f', cfg.umbral_factor));
grid on; legend('Location', 'northeastoutside');

% 6. Recrear Visualización 2: K-Means (Dual o Estándar)
figure('Name', ['Visualizador: K-Means - ' file]);
gscatter(dat.vector_norm(:,idx1), dat.vector_norm(:,idx2), res.predicciones_km, 'rgbk', 'osd*');
hold on;
plot(mod.centroides_km(:,idx1), mod.centroides_km(:,idx2), 'm+', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Centroides K-Means (Proj L1)');
plot(centroides(:,idx1), centroides(:,idx2), 'kx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Centroides Ref');
xlabel(sprintf('%d. %s (Z-score)', idx1, nombres_caract_full{idx1}));
ylabel(sprintf('%d. %s (Z-score)', idx2, nombres_caract_full{idx2}));
if isfield(cfg, 'usar_dos_derivaciones') && cfg.usar_dos_derivaciones
    title(sprintf('K-Means Dual 18D (Proyección L1)\nk=%d, Distancia: %s', cfg.k_clusters, cfg.k_distance));
else
    title(sprintf('Clasificación por Clustering (K-Means)\nk=%d, Distancia: %s', cfg.k_clusters, cfg.k_distance));
end
grid on; legend('Location', 'northeastoutside');

% 7. Recrear Visualización 3: Espectros agrupados (si están disponibles)
if isfield(dat, 'espectros') && isfield(dat, 'frecuencias')
    figure('Name', ['Visualizador: DEP por Clase - ' file]);
    clases_plot = [clases_unicas, {'Otro'}];
    colores = {'r', 'g', 'b', 'k'};

    for c = 1:length(clases_plot)
        ax = subplot(length(clases_plot), 1, c);
        hold on; grid on;
        title(['K-Means: ', clases_plot{c}], 'FontWeight', 'bold');
        ylabel('DEP');
        
        idx_pred_km = strcmp(res.predicciones_km, clases_plot{c});
        if any(idx_pred_km)
            segmentos_clase = find(idx_pred_km);
            for s = segmentos_clase'
                plot(ax, dat.frecuencias{s}, dat.espectros{s}, 'Color', colores{c});
            end
        else
            text(0.5, 0.5, 'Sin segmentos en esta categoría', 'HorizontalAlignment', 'center');
        end
        xlim([0 10]);
        if c == length(clases_plot), xlabel('Frecuencia (Hz)'); end
    end
else
    fprintf('\nNota: Los espectros no se guardaron en este archivo de experimento.\n');
end

fprintf('\n--- VISUALIZACIÓN COMPLETADA ---\n');
