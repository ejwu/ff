for f in out-*
do
    lua=${f#out-}
    java -jar bin/unluac.jar $f > $lua
    echo $lua
done
