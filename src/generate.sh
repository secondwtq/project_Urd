python lua-pystiller.py -i urdmain.lua -o urdmain.luap -a dofile
rm main.luacb
lua ../util/bin2cX.lua ./urdmain.luap >> main.luacb
make clean