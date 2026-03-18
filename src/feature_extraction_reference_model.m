addpath(fullfile('..', 'lib'));
archivos = dir(fullfile('..', 'data', 'Señales de prueba', '*.dat'));
num_archivos = length(archivos);

show_plots = false;

% Pre-asignar la matriz
vector_caract = zeros(num_archivos, 9); 
% Crear un array de celdas para guardar la clase de cada archivo
etiquetas = cell(num_archivos, 1); 
% Variables para guardar los espectros
espectros = cell(num_archivos, 1);
frecuencias = cell(num_archivos, 1);
nombres_leyenda = cell(num_archivos, 1);

for i = 1:num_archivos
    nombre_archivo = archivos(i).name;
    
    % 1. Extraer la etiqueta basándonos en el nombre del archivo
    if contains(nombre_archivo, 'tv', 'IgnoreCase', true)
        etiquetas{i} = 'TV'; % Taquicardia Ventricular
    elseif contains(nombre_archivo, 'ts', 'IgnoreCase', true)
        etiquetas{i} = 'TSV'; % Taquicardia Supraventricular
    elseif contains(nombre_archivo, 'sn', 'IgnoreCase', true)
        etiquetas{i} = 'RS'; % Ritmo Sinusal
    else
        etiquetas{i} = 'Otro';
    end

    % Leer datos
    datos = leedatos(fullfile('..', 'data', 'Señales de prueba', nombre_archivo));
    
    % Procesamiento inicial de la señal
    ECG = datos.ECG(1,:);
    fs = datos.fs;
    ECG_sin_continua = ECG - mean(ECG);
    
    % Calcular la Densidad Espectral de Potencia
    [pxx, f] = pwelch(ECG_sin_continua, hamming(round(2*fs)), [], [], fs);
    
    % Guardamos los datos del espectro para pintarlos juntos al final
    espectros{i} = pxx;
    frecuencias{i} = f;
    nombres_leyenda{i} = nombre_archivo;

    % Extraer características
    vector_caract(i, :) = extraer_caracteristicas(pxx, f);
    
    if show_plots
        figure
        title(nombre_archivo)
        subplot(2,1,1); plot(f,pxx)
        subplot(2,1,2); plot((1:length(ECG))/fs,ECG)
    end
end

% Normalizamos con Z-Score
vector_caract_norm = zscore(vector_caract);

%% VISUALIZACIÓN DE RESULTADOS

nombres_caract = {'1. Frec. Pico Máx', '2. Ancho Pico', '3. Num. Armónicos', ...
                  '4. Skewness', '5. Kurtosis', '6. Centroide Espectral', ...
                  '7. Pot. Total', '8. Pot. Pico', '9. Ratio PP/PT'};

% 1. Crear matriz de Boxplots (3x3 para las 9 características)
figure
for c = 1:9
    subplot(3, 3, c);
    % Genera el boxplot agrupando por la etiqueta (TV, TSV, RS)
    boxplot(vector_caract_norm(:, c), etiquetas);
    title(nombres_caract{c}, 'FontWeight', 'bold');
    ylabel('Valor (Z-score)');
    grid on;
end

% 2. Gráfico de Dispersión (Scatter Plot)
figure('Name', 'Separabilidad de Arritmias (Scatter)');
gscatter(vector_caract_norm(:,1), vector_caract_norm(:,6), etiquetas, 'rgb', 'osd');
xlabel('1. Frecuencia del Pico (Z-score)');
ylabel('6. Centroide Espectral (Z-score)');
title('Distribución 2D: Frecuencia Pico vs Centroide');
grid on;

% 3. Visualización de espectros por tipo

figure

% Creamos los 3 ejes (uno para cada tipo)
ax1 = subplot(3,1,1); title('Taquicardia Ventricular (TV)', 'FontWeight', 'bold'); 
hold on; grid on; ylabel('Magnitud DEP');
ax2 = subplot(3,1,2); title('Taquicardia Supraventricular (TSV)', 'FontWeight', 'bold'); 
hold on; grid on; ylabel('Magnitud DEP');
ax3 = subplot(3,1,3); title('Ritmo Sinusal (RS)', 'FontWeight', 'bold'); 
hold on; grid on; ylabel('Magnitud DEP'); xlabel('Frecuencia (Hz)');

% Bucle para pintar cada espectro en su subplot correspondiente
for i = 1:num_archivos
    if strcmp(etiquetas{i}, 'TV')
        plot(ax1, frecuencias{i}, espectros{i}, 'LineWidth', 1.5, 'DisplayName', nombres_leyenda{i});
    elseif strcmp(etiquetas{i}, 'TSV')
        plot(ax2, frecuencias{i}, espectros{i}, 'LineWidth', 1.5, 'DisplayName', nombres_leyenda{i});
    elseif strcmp(etiquetas{i}, 'RS')
        plot(ax3, frecuencias{i}, espectros{i}, 'LineWidth', 1.5, 'DisplayName', nombres_leyenda{i});
    end
end

% Mostrar leyendas en cada subplot
legend(ax1, 'show'); legend(ax2, 'show'); legend(ax3, 'show');

% Sincronizar el zoom en el eje X de los 3 subplots
linkaxes([ax1, ax2, ax3], 'x');

% Limitar el eje X. El ECG suele tener su info más relevante por debajo de 30-40 Hz.
% Si ves que tus picos están muy a la izquierda, puedes cambiar este valor a [0 20]
xlim(ax1, [0 20]);

%% EXPORTAR MODELO PARA EJERCICIO 3 (FASE 0)

% 1. Parámetros de normalización originales
media_ej2 = mean(vector_caract);
std_ej2 = std(vector_caract);

% 2. Calcular Centroides por Clase (en el espacio Z-score)
clases_unicas = {'TV', 'TSV', 'RS'};
centroides = zeros(length(clases_unicas), 9);

for c = 1:length(clases_unicas)
    idx = strcmp(etiquetas, clases_unicas{c});
    if any(idx)
        centroides(c, :) = mean(vector_caract_norm(idx, :));
    end
end

% 3. Guardar en archivo .mat (incluyendo datos normalizados para el umbral de rechazo)
if ~exist(fullfile('..', 'models'), 'dir'), mkdir(fullfile('..', 'models')); end
save(fullfile('..', 'models', 'modelo_referencia_1Lead.mat'), 'media_ej2', 'std_ej2', 'centroides', 'clases_unicas', 'vector_caract_norm', 'etiquetas');
fprintf('\n[FASE 0] Modelo de referencia exportado a "models/modelo_referencia_1Lead.mat"\n');
