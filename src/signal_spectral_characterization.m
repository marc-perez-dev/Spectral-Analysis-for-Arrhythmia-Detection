%% CARGAMOS LOS DATOS
addpath(fullfile('..', 'lib'));
datos = leedatos(fullfile('..', 'data', 'Señales de prueba'));


    % señal ECG y frecuencia de muestreo
ECG = datos.ECG(1,:);
fs = datos.fs;
    % FFT
transformada_Fourier = fft(ECG);
abs_transformadaFourier = abs(transformada_Fourier);
    % número de muestras
N = length(transformada_Fourier);
    % vector de frecuencias
Hz = linspace(0,fs,N);

    % representación
figure;
plot(Hz, abs_transformadaFourier);
xlabel('Frecuencia (Hz)');
ylabel('FFT');
title('Transformada de Fourier del ECG');
grid on;

    %% Frecuencia de pico principal
[valor_max, imax] = max(abs_transformadaFourier);
imax = imax + 1;
fc_pico = Hz(imax);
disp(['Frecuencia de pico principal = ', num2str(fc_pico), ' Hz'])

    %% Ancho de pico principal
media_potencia = valor_max/sqrt(2);

izq = imax;
while izq > 1 && abs_transformadaFourier(izq) >= media_potencia
    izq = izq - 1;
end
der = imax;
while der < length(abs_transformadaFourier) && abs_transformadaFourier(der) >= media_potencia
    der = der + 1;
end

ancho_pp = Hz(der) - Hz(izq);
disp(['Ancho de pico principal = ', num2str(ancho_pp), ' Hz'])

    %% Armónicos
    % Usamos la función de la librería para encontrar armónicos con mayor precisión
    harmonicos = encontrarHarmonicos(abs_transformadaFourier, Hz, 0.15, 50);
    
    figure;
    plot(Hz, abs_transformadaFourier, 'LineWidth', 2); hold on;
    plot(Hz(harmonicos), abs_transformadaFourier(harmonicos), 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', 2);
    xlabel('Frecuencia (Hz)');
    ylabel('FFT');
    title('Picos del espectro (Armónicos detectados)');
    grid on;
    xlim([0 20]);
    
    num_harmonicos = length(harmonicos);
    disp(['Número de armónicos detectados = ', num2str(num_harmonicos)])

    %% Resolución en frecuencia
delta_f = fs / N;
disp(['Resolución en frecuencia = ', num2str(delta_f), ' Hz'])


%% CÁLCULO DE LA VARIABILIDAD DEL ESPECTRO

    %% 1. cálculo de los primeros 4s de señal (1000 PRIMERAS MUESTRAS)
segmento1 = ECG(1:1000);
        % FFT del segmento
    FFT_segmento1 = fft(segmento1);
    absFFT_segmento1 = abs(FFT_segmento1);
        % número de muestras
    N = length(FFT_segmento1);
        % vector de frecuencias
    Hz = linspace(0,fs,N);

    %% 2. representación del espectro
figure;
plot(Hz, absFFT_segmento1, 'LineWidth', 1.5);
hold on;
grid on;
xlabel('Frecuencia (Hz)');
ylabel('FFT');
title('Comparación de la FFT en dos segmentos de 4 s');

    %% 3. cálculo de los siguientes 4s de la señal (1001 A 2000 MUESTRAS)
segmento2 = ECG(1001:2000);
        % FFT del segmento
    FFT_segmento2 = fft(segmento2);
    absFFT_segmento2 = abs(FFT_segmento2);
        % número de muestras
    N = length(FFT_segmento2);
        % vector de frecuencias
    Hz = linspace(0,fs,N);

    %% 4. representación del espectro
plot(Hz, absFFT_segmento2, 'LineWidth', 1.5);
legend('Primeros 4 s', 'Siguientes 4 s');
xlim([0 20]);

%% CÁLCULO CON EL MÉTODO DE WELCH

    %% 1. Cálculo densidad espectral para ventana de 4s
        % definimos los parámetros de la ventana de Welch para 4s
window4 = 1024;      % 1024 muestras en 4s (256 muestras en 1s)
noverlap4 = 512;     % 50% de solapamiento
nfft4 = 8192;

[Pxx4, F4] = pwelch(ECG, window4, noverlap4, nfft4, fs);

        % representamos gráficamente la ventana calculada
figure;
plot(F4, Pxx4, 'LineWidth', 1.5);
xlabel('Frecuencia (Hz)');
ylabel('Densidad espectral de potencia');
title('Método de Welch con ventana ~4 s');
grid on;
xlim([0 20])

    %% 2. ¿Sobre cuántos tramos se realiza el promediado?
N4 = length(ECG);
K4 = floor((N4-noverlap4)/(window4-noverlap4));

disp(['Número de tramos promediados (ventana ~4 s): ', num2str(K4)]);

    %% 3. Repetimos la ventana pero ahora con 1s
        % definimos los parámetros de la ventana de Welch para 4s
window1 = 256;      % 256 muestras en 1s
noverlap1 = 128;     % 50% de solapamiento
nfft1 = 8192;

[Pxx1, F1] = pwelch(ECG, window1, noverlap1, nfft1, fs);

        % representamos gráficamente la ventana calculada
figure;
plot(F1, Pxx1, 'LineWidth', 1.5);
xlabel('Frecuencia (Hz)');
ylabel('Densidad espectral de potencia');
title('Método de Welch con ventana ~1 s');
grid on;
xlim([0 20]);

N1 = length(ECG);
K1 = floor((N1-noverlap1)/(window1-noverlap1));

disp(['Número de tramos promediados (ventana ~1 s): ', num2str(K1)]);

    %% 4. ¿Cómo cambia el ancho del pulso?
        % comparamos ambos espectros
figure;
plot(F4, Pxx4, 'LineWidth', 1.5); hold on;
plot(F1, Pxx1, 'LineWidth', 1.5);
xlabel('Frecuencia (Hz)');
ylabel('Densidad espectral de potencia');
title('Comparación Welch: ventana ~4 s vs ventana ~1 s');
legend('Ventana ~4 s', 'Ventana ~1 s');
grid on;
xlim([0 20]);