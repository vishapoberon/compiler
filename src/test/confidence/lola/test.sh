#!
. ../testenv.sh
voc LSS.Mod LSB.Mod LSC.Mod LSV.Mod lola.Mod -m
./Lola RISC5.Lola result
. ../testresult.sh
