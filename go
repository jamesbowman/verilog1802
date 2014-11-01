set -e
# python prepare.py ; exit
make
time obj_dir/Vtestbench alltest.fr
grep RESULT log || true
# ./1802sim CF1802 ; exit
# ./1802sim CF1802 < _1
# qdiff /data/xlog /data/1
