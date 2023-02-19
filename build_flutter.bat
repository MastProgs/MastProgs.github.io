cd ./flutter
cd ./mastprogs

call flutter build web

cd ..
cd ..

xcopy /e /y .\flutter\mastprogs\build\web\* .\docs\