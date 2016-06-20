#branch=v2docs
#ssh pi@pie "cd projects/oberon/vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh dave@dcb "cd projects/oberon/vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh dave@nas-ub64 "cd vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh dave@lub32 "cd vishap/voc && sudo git checkout $branch && sudo make clean" &
#ssh root@nas-ob32 "cd vishap/voc && git checkout $branch && make clean" &
#ssh root@oberon "cd vishap/voc && git checkout $branch && make clean" &

declare -A VOCLOGIN
VOCLOGIN[pi]=pi@pie
VOCLOGIN[darwin]=dave@dcb
VOCLOGIN[ub64]=dave@nas-ub64
VOCLOGIN[lub32]=dave@lub32
VOCLOGIN[ob32]=root@nas-ob32
VOCLOGIN[fb64]=root@oberon

declare -A VOCDIR
VOCDIR[pi]=projects/oberon/vishap/voc
VOCDIR[darwin]=projects/oberon/vishap/voc
VOCDIR[ub64]=vishap/voc
VOCDIR[lub32]=vishap/voc
VOCDIR[ob32]=vishap/voc
VOCDIR[fb64]=vishap/voc

declare -A VOCSUDO
VOCSUDO[pi]="sudo "
VOCSUDO[darwin]="sudo "
VOCSUDO[ub64]="sudo "
VOCSUDO[lub32]="sudo "
VOCSUDO[ob32]=""
VOCSUDO[fb64]=""

for MACHINE in "${!VOCLOGIN[@]}"
do
SETBRANCH="${VOCSUDO[$MACHINE]} git checkout $branch"
PULL="${VOCSUDO[$MACHINE]} git pull"
MAKE="${VOCSUDO[$MACHINE]} make full"
ssh ${VOCLOGIN[$MACHINE]} "cd ${VOCDIR[$MACHINE]} && $SETBRANCH && $PULL && $MAKE" | perl -pe "use POSIX strftime; print strftime \"%H:%M:%S $MACHINE: \", localtime" | tee log/$MACHINE.log &
done
