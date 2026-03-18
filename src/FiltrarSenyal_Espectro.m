function senyal_filtrada = FiltrarSenyal_Espectro(senyal, fs, f_alto, f_bajo)
    % FILTRARSENYAL_ESPECTRO Filtra un vector de señal ECG para análisis espectral.
    % Elimina vagabundeo de línea base y ruido de alta frecuencia/red eléctrica.
    
    % Frecuencias predeterminadas optimizadas para arritmias (0.5 - 40 Hz)
    if nargin < 3 || isempty(f_alto), f_alto = 0.5; end
    if nargin < 4 || isempty(f_bajo), f_bajo = 40; end
    
    nyquist = fs / 2;
    
    % 1) Filtrado Paso Alto (para eliminar línea base y componente continua)
    [b_hp, a_hp] = butter(4, f_alto / nyquist, 'high');
    
    % 2) Filtrado Paso Bajo (elimina ruido muscular e interferencia de red de 50Hz)
    [b_lp, a_lp] = butter(4, f_bajo / nyquist, 'low');
    
    % Aplicar filtros (asumiendo que senyal es un vector fila)
    senyal_filtrada = filtfilt(b_hp, a_hp, senyal);
    senyal_filtrada = filtfilt(b_lp, a_lp, senyal_filtrada);
end