function harmonicos = encontrarHarmonicos(s, f, umbral, corte)
    % Busca picos en múltiplos de la frecuencia fundamental (armónicos)
    if nargin < 4
        corte = max(f); % Límite superior de búsqueda opcional
    end
    
    harmonicos = [];
    [valorpico, idxpico] = max(s); % Identifica el pico fundamental
    n = round(length(f)/idxpico);  % Máximo teórico de armónicos posibles
    
    for i=2:n
        % Calcula la posición teórica del armónico i
        muestra = (min(idxpico * i, length(f)));
        
        if f(muestra) > corte
            break
        end
        
        % Define ventana de búsqueda alrededor del múltiplo teórico
        lim_inf = max(1, round(muestra*(1-umbral)));
        lim_sup = min(length(f), round(muestra*(1+umbral)));
        
        % Busca el máximo local real dentro de la ventana definida
        ventana_s = s(lim_inf:lim_sup);
        ventana_f = f(lim_inf:lim_sup);
        [~, idx] = max(ventana_s);
        muestra_cercana = find(f == ventana_f(idx), 1);
        
        % Evita duplicar picos y valida que tenga una potencia mínima (1% del pico)
        if ismember(muestra_cercana, harmonicos)
            continue
        end
        
        if s(muestra_cercana) > 0.01*valorpico
            harmonicos(end+1) = (double(muestra_cercana));
        end
    end
end