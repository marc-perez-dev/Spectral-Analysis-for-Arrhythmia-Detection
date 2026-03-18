function features = extraer_caracteristicas(pxx, f)
    % EXTRAER_CARACTERISTICAS Extrae un vector de 9 características a partir
    % de la densidad espectral de potencia (pxx) y las frecuencias (f).
    
    % 1. Pico máximo y su frecuencia
    [valormax, maxidx] = max(pxx);
    f_max = f(maxidx);
    
    % 2. Ancho del pico
    [idx_derecha, idx_izquierda] = sacarLados(maxidx, valormax, pxx);
    anchoPico50 = f(idx_derecha) - f(idx_izquierda);
    
    % 3. Cantidad de armónicos
    harmonicos = encontrarHarmonicos(pxx, f, 0.15);
    num_harmonicos = length(harmonicos);
    
    % 4 & 5. Estadísticas de forma del espectro
    skew_pxx = skewness(pxx);
    kurt_pxx = kurtosis(pxx);
    
    % 6. Centroide espectral (Momento 1)
    M1 = sum(pxx .* f) / sum(pxx);
    
    % 7 & 8. Potencias y su relación
    potencia_total = sum(pxx);
    potencia_pico = sum(pxx(idx_izquierda:idx_derecha));
    PPBP = potencia_pico / potencia_total;
    
    % 9. Frecuencia que acumula el 75% de la potencia
    potencia_acumulada = cumsum(pxx) / potencia_total;
    idx_75 = find(potencia_acumulada >= 0.75, 1);
    Fb75 = f(idx_75);
    
    % Construir y devolver el vector fila de características
    features = [f_max, anchoPico50, num_harmonicos, skew_pxx, ...
                kurt_pxx, M1, valormax, PPBP, Fb75];
end