cd ./flutter
cd ./mastprogs_v2

call flutter build web --web-renderer canvaskit --release

cd ..
cd ..

xcopy /e /y .\flutter\mastprogs_v2\build\web\* .\docs\