# Thin the Payload folder (the App Store separates platforms automatically; this is only for building an unsigned IPA)

foreachThin(){
  for file in $1/*
  do
      if test -f $file
      then
           mime=$(file --mime-type -b $file)
           if [ "$mime" == 'application/x-mach-binary' ]  || [ "${file##*.}"x = "dylib"x ]
           then
                echo thin $file
                xcrun -sdk iphoneos lipo "$file" -thin arm64 -output "$file"
                xcrun -sdk iphoneos bitcode_strip "$file" -r -o  "$file"
                strip -S -x "$file" -o "$file"
           fi
      fi
      if test -d $file
      then
          foreachThin $file
      fi
  done
}

foreachThin ./Payload
