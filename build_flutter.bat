cd ./flutter
cd ./mastprogs_v3

call flutter build web --release --no-web-resources-cdn --no-wasm-dry-run

cd ..
cd ..

xcopy /e /y .\flutter\mastprogs_v3\build\web\* .\docs\
