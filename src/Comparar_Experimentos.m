%% COMPARAR_EXPERIMENTOS.M - Dashboard Clínico y Mapa de Calor Evolutivo
clc; clear; close all;
addpath(fullfile('..', 'lib'));

% 1. Selección de archivos
carpeta_res = fullfile('..', 'Resultados_Experimentos');
if ~exist(carpeta_res, 'dir'), error('No existe la carpeta de resultados.'); end

[files, path] = uigetfile(fullfile(carpeta_res, '*.mat'), ...
    'Selecciona experimentos (Ctrl+Click)', 'MultiSelect', 'on');

if isequal(files, 0), disp('Cancelado.'); return; end
if ischar(files), files = {files}; end

num_exp = length(files);
nombres_exp = cell(1, num_exp);
metricas_consenso = zeros(1, num_exp);
detecciones_TV = zeros(1, num_exp);
rechazos_Otro = zeros(1, num_exp);

% Mapeo
cat_map = containers.Map({'TV', 'TSV', 'RS', 'Otro'}, {1, 2, 3, 4});
cmap = [0.85 0.20 0.20;  % Rojo intenso (TV)
        0.20 0.60 1.00;  % Azul claro (TSV)
        0.40 0.80 0.40;  % Verde suave (RS)
        0.80 0.80 0.80]; % Gris claro (Otro/Ruido)

%% 2. Procesamiento Inteligente de Datos
% Cargamos el primer experimento para sacar la referencia (TM) y segmentos
load(fullfile(path, files{1}), 'experimento');
segmentos = experimento.datos.nombres_segmentos;

% Iniciamos la matriz del heatmap. 
% COLUMNA 1: Template Matching (Baseline). COLUMNAS 2 a N+1: K-Means de cada exp.
datos_heatmap = zeros(length(segmentos), num_exp + 1);

% Rellenamos la columna 1 (Baseline TM)
for s = 1:length(segmentos)
    datos_heatmap(s, 1) = cat_map(experimento.resultados.predicciones_tm{s});
end

x_labels_heatmap = cell(1, num_exp + 1);
x_labels_heatmap{1} = 'Baseline (TM)';

for i = 1:num_exp
    load(fullfile(path, files{i}), 'experimento');
    
    % MEJORA 1: Nombres informativos basados en Hiperparámetros
    k_val = experimento.config.k_clusters;
    u_val = experimento.config.umbral_factor;
    nombres_exp{i} = sprintf('KM (k=%d, u=%.1f)', k_val, u_val);
    x_labels_heatmap{i+1} = nombres_exp{i};
    
    % Extraer métricas
    metricas_consenso(i) = experimento.resultados.consenso;
    
    % Extraer predicciones KM para este experimento
    km_labels = experimento.resultados.predicciones_km;
    for s = 1:length(segmentos)
        datos_heatmap(s, i+1) = cat_map(km_labels{s});
    end
    
    % MEJORA 2: Métricas Clínicas
    detecciones_TV(i) = sum(strcmp(km_labels, 'TV'));
    rechazos_Otro(i) = sum(strcmp(km_labels, 'Otro'));
end

%% 3. VISUALIZACIÓN I: DASHBOARD DE MÉTRICAS CLÍNICAS
figure('Name', 'Dashboard de Comparación: K-Means vs Hiperparámetros', 'Position', [100 100 1000 400]);

subplot(1, 3, 1);
bar(metricas_consenso, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'none');
set(gca, 'XTick', 1:num_exp, 'XTickLabel', nombres_exp, 'XTickLabelRotation', 45);
ylabel('% de Consenso con TM'); title('Estabilidad (Consenso)'); grid on; ylim([0 100]);

subplot(1, 3, 2);
bar(detecciones_TV, 'FaceColor', cmap(1,:), 'EdgeColor', 'none');
set(gca, 'XTick', 1:num_exp, 'XTickLabel', nombres_exp, 'XTickLabelRotation', 45);
ylabel('Nº de Segmentos TV'); title('Sensibilidad a Malignidad (TV)'); grid on;

subplot(1, 3, 3);
bar(rechazos_Otro, 'FaceColor', cmap(4,:), 'EdgeColor', 'none');
set(gca, 'XTick', 1:num_exp, 'XTickLabel', nombres_exp, 'XTickLabelRotation', 45);
ylabel('Nº de Segmentos Rechazados'); title('Filtrado de Ruido (Otro)'); grid on;

%% 4. VISUALIZACIÓN II: MAPA DE CALOR EVOLUTIVO
figure('Name', 'Evolución de Predicciones por Experimento', 'Position', [150 150 900 700]);

imagesc(datos_heatmap);
colormap(cmap);

% Estética mejorada
set(gca, 'YTick', 1:length(segmentos), 'YTickLabel', segmentos, 'TickDir', 'out');
set(gca, 'XTick', 1:(num_exp+1), 'XTickLabel', x_labels_heatmap, 'XTickLabelRotation', 30);
title('Evolución de las Clasificaciones según Hiperparámetros');

% Separador visual entre TM (Baseline) y los algoritmos K-Means
hold on;
line([1.5 1.5], [0.5 length(segmentos)+0.5], 'Color', 'k', 'LineWidth', 3);

% Cuadrícula sutil
for i = 2:(num_exp+1)
    line([i+0.5 i+0.5], [0.5 length(segmentos)+0.5], 'Color', 'w', 'LineWidth', 1);
end
for i = 1:length(segmentos)
    line([0.5 num_exp+1.5], [i+0.5 i+0.5], 'Color', 'w', 'LineWidth', 1);
end

% Leyenda personalizada
L1 = plot(nan, nan, 's', 'MarkerSize', 12, 'MarkerFaceColor', cmap(1,:), 'MarkerEdgeColor', 'none');
L2 = plot(nan, nan, 's', 'MarkerSize', 12, 'MarkerFaceColor', cmap(2,:), 'MarkerEdgeColor', 'none');
L3 = plot(nan, nan, 's', 'MarkerSize', 12, 'MarkerFaceColor', cmap(3,:), 'MarkerEdgeColor', 'none');
L4 = plot(nan, nan, 's', 'MarkerSize', 12, 'MarkerFaceColor', cmap(4,:), 'MarkerEdgeColor', 'none');
legend([L1, L2, L3, L4], {'TV (Maligna)', 'TSV (Benigna)', 'RS (Normal)', 'Otro (Rechazo)'}, ...
    'Location', 'northeastoutside', 'FontSize', 11);

fprintf('\n--- COMPARATIVA COMPLETADA ---\n');