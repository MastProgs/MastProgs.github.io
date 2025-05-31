cd ./flutter
cd ./mastprogs_v2

call flutter build web --release

cd ..
cd ..

xcopy /e /y .\flutter\mastprogs_v2\build\web\* .\docs\