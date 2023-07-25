run ./data_source/installBenchmarks.m
if isdir('targets')
    mkdir('targets')
end 
exportAllBenchmarksToMatFile( )