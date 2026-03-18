function datos = leedatos(fpath)

%path_actual = pwd;

[ecg,fs,n_signals,fname,fpath]=leedat(fpath);



fichero = [fpath fname(1:end-4)];

datos.ECG = ecg;
datos.nombre = fname;
datos.fs = fs;

%cd(path_actual);
