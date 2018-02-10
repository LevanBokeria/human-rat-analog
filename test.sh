for subj in */; do
for mrifolder in $subj*/ ; do
    for subfold in $mrifolder*/; do
      for niifile in $subfold/*.nii.gz; do
        if [[ $niifile != "*vol*.nii.gz" && "$niifile" != "*\**" ]] ; then 
          echo "$niifile"
        fi
      done
    done
done
done
