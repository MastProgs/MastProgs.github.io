cd ./flutter
cd ./mastprogs

call flutter build web --web-renderer html --release

cd ..
cd ..

xcopy /e /y .\flutter\mastprogs\build\web\* .\docs\