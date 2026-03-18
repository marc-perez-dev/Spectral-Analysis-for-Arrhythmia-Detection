function [idx_derecha, idx_izquierda] = sacarLados(idxmax,valormax,abs_transformada)
mitad_principal = valormax/2;
idx_actual = idxmax;
valoractual = valormax;
while idx_actual > 1 && valoractual > mitad_principal
    idx_actual = idx_actual - 1;
    valoractual = abs_transformada(idx_actual);
end
idx_izquierda = idx_actual;

idx_actual = idxmax;
valoractual = valormax;
n_puntos = length(abs_transformada);
while idx_actual < n_puntos && valoractual > mitad_principal
    idx_actual = idx_actual + 1;
    valoractual = abs_transformada(idx_actual);
end
idx_derecha = idx_actual;