#for f in pvrccz/*.pvr.ccz

for f in ~/ff/$1/files/res_sub/arts/goods/*.pvr.ccz
do
    pvr=${f%.ccz}
    f2=${f%.pvr.ccz}
    echo $f
    echo $pvr
    echo $f2
    dotnet run $f2 --project ~/cczp/DecryptCocos2dAsset/DecryptCocos2dAsset
    TexturePacker $pvr --data $f2 --algorithm Basic --no-trim --png-opt-level 0 --disable-auto-alias --extrude 0
done
