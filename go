set -e
# python prepare.py ; exit
make
# obj_dir/Vtestbench software/CF1802.hex
ANS=software/anstests0.10
echo BYE | cat $ANS/tester.fr $ANS/core.fr - >0
time obj_dir/Vtestbench software/CF1802.hex < 0
# time echo BYE | cat $ANS/tester.fr $ANS/core.fr - | obj_dir/Vtestbench software/CF1802.hex
grep RESULT log || true
# ./1802sim CF1802 ; exit
# ./1802sim CF1802 < _1
# qdiff /data/xlog /data/1
