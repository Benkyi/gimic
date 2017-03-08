#!/bin/bash

function centroid() { atoms="$@"; for i in $atoms; do awk -v i=$i '{ if (NR == i+1) print $0 }' coord; done | awk '{ x+=$1; y+=$2; z+=$3; n++} END{ print x/n, y/n, z/n; }'; }
function dist() { awk -v a1="$1" -v a2="$2" '{ if (NR == a1+1) { x+=$1;y+=$2;z+=$3;}; if (NR == a2+1) {x-=$1;y-=$2;z-=$3} } END{ dist=sqrt(x*x+y*y+z*z); print dist, dist*0.5; }' coord ; }

function userInp()
{
    local __resultVar=$1
    local __varValue="$2"
    local localResult="$2"
    printf "\nPress [a] to enter atomic indices or press [v] to enter the desired value\n"
    read accept
    if [ ! -z $accept ] && [ $accept == "a" ]
    then
        printf "\nEnter the indices of the selected atoms to calculate their midpoint and then press enter.\n\n" 
     atoms=0; read atoms
     CENTROID=$(centroid $atoms)
     Dx=$( echo $CENTROID | awk '{print $1} ' )
     Dy=$( echo $CENTROID | awk '{print $2} ' )
     Dz=$( echo $CENTROID | awk '{print $3} ' )
     #echo "Centroid:"; printf "("$Dx"; "$Dy"; "$Dz")\n"
     __varValue=$( awk -v Dx=$Dx -v Dy=$Dy -v Dz=$Dz -v Bx=$Bx -v By=$By -v Bz=$Bz BEGIN'{dist=sqrt( (Bx-Dx)*(Bx-Dx) + (By-Dy)*(By-Dy) + (Bz-Dz)*(Bz-Dz) ); print dist}' )
     
     printf  "\nDo you accept $__resultVar=$__varValue bohr?\nPress [n] to change\n"
     read accept;
     if [ ! -z $accept ] && [ $accept == "n" ]
     then
         printf "$__resultVar="; read __varValue
     fi # if centroid calculation not accepted 
     elif [ ! -z $accept ] && [ $accept == "v" ]
     then
         printf "$__resultVar="; read __varValue
         printf  "\nDo you accept $__resultVar=$__varValue bohr?\nPress [n] to change\n"
     read accept;
     if [ ! -z $accept ] && [ $accept == "n" ]
     then
         printf $__resultVar=$__varValue
     fi
fi # end if accept out = 10

eval $__resultVar="'$__varValue'"
}


printf "\nStarting current profile analysis\n"
printf "\nUsing atomic units of length\n\n"

echo "Define the bond perpendicular to which to integrate"; echo
echo "Enter the indices of the atoms according to the coord file"
printf "Atom 1:  "; read atom1; 
printf "Atom 2:  "; read atom2
distance=$( awk -v a1="$atom1" -v a2="$atom2" '{ if (NR == a1+1) { x+=$1;y+=$2;z+=$3;}; if (NR == a2+1) {x-=$1;y-=$2;z-=$3} } END{ dist=sqrt(x*x+y*y+z*z); print dist*0.5; }' coord ; )
bond=$atom1","$atom2

dirname=current_profile_$atom1.$atom2
	
# If we are not in the current_profile folder, check if it exists. If it did, just go there. If it did not, create it and copy the necessary files
dir=$(pwd | grep "current_profile")
#echo $dir
if [ -z $dir ] # if the path does not contain "current_profile", $dir is empty, so the directory either does not exist, or we are not inside it
then
    #echo "Currently not in the directory current_profile"
    if [ -d $dirname ] 
    then
	printf "\n\n*** Directory already exists.\n\nCalculation parameters:\n"
	grep "bond=\|fixed=\|up=\|down=\|MF=" $dirname/gimic.int
	echo "Enter [y] to overwrite or any key to exit."; read accept
	if [ -z $accept ] || [ ! $accept == "y" ]  # if the variable is empty or different from "y", exit 
	then 
	    exit
	else
	    rm -f $dirname/*out $dirname/*inp # Remove leftover input and output to avoid confusion
	fi 
    else
	if [ -e MOL ] && [ -e XDENS ] && [ -e coord ]
	then
	    mkdir $dirname
	    cp coord $dirname/
	    echo "Directory $dirname created."; echo
	else
	    echo "Please run the current profile analysis from a directory containing the files MOL, XDENS and coord"
	    exit
	fi # end if MOL, XDENS, coord exist
    fi # end if current_profile_#.#
fi # end if directory current_profile_#.# exists or we are inside it

# Coordinates of the centre:
BOND=$(centroid $atom1 $atom2)
Bx=$( echo $BOND | awk '{print $1} ' )
By=$( echo $BOND | awk '{print $2} ' )
Bz=$( echo $BOND | awk '{print $3} ' )

#echo "Bond centre coordinates:"
#printf "("$Bx";"$By";"$Bz")\n"

printf "\nEnter the index of the fixed atom:\n"
read fixed

printf "\n\nSTARTING POINT OF THE INTEGRATION\n"
userInp start $start

printf "\nEND POINT OF THE INTEGRATION\n"
out=10
printf "\nDo you accept out=$out bohr?"
userInp out $out

up=10
down=10
printf "\n\nUPPER AND LOWER BOUNDS OF THE INTEGRATION\n"
printf  "\nDo you accept up=$up bohr and down=$down bohr?\nPress [n] to change\n"
read accept;
if [ ! -z $accept ] && [ $accept == "n" ]
then
    printf "up="; read up
    printf "down="; read down
fi

delta=0.02
printf "\n\nWIDTH OF THE SLICES\n"
printf  "\nDo you accept delta=$delta bohr?\nPress [n] to change\n"
read accept;
if [ ! -z $accept ] && [ $accept == "n" ]
then
    printf "delta="; read delta
fi

nsteps=$( awk -v start=$start -v out=$out -v delta=$delta 'BEGIN{nsteps=(out+start)/delta; if (nsteps > 0) {printf("%d",nsteps)} else {printf("%d",-nsteps);}; }'   )


# Practice has shown that for delta=0.1, the spacing value should be 0.02 in order to have at least 9 Gaussian points per slice
# If the delta is smaller than 0.1, recalculate:
spacingFactor=$( awk -v delta=$delta 'BEGIN{ printf("%.2f",delta/0.02) }' )    # how many times smaller the chosen delta value is
spacing=$( awk -v f=$spacingFactor 'BEGIN{ printf("%.3f",0.01*f) }' )

printf "\n\nSPACING\n"
printf  "\nDo you accept spacing=[$spacing, $spacing, $spacing]?\nPress [n] to change\n"
read accept;
if [ ! -z $accept ] && [ $accept == "n" ]
then
    printf "spacing="; read spacing
fi

MF=z
printf  "\nMagnetic field direction = $MF. Do you accept?\nPress [n] to change\n"
read accept;
if [ ! -z $accept ] && [ $accept == "n" ]
then
    printf "MF="; read MF
fi

string="s/@bond@/$bond/; s/@fixed@/$fixed/; s/@distance@/$distance/; s/@up@/$up/; s/@down@/$down/; s/@MF@/$MF/; s/@spacing@/$spacing/g"
sed "$string" /wrk/mariavd/scripts/gimic/gimic.int > $dirname/gimic.int

end=$( awk -v delta=$delta -v start=$start 'BEGIN{print delta-start}' ) 

#echo "Enter title:"
#read heading
#heading=\"$heading"\n bond=["$bond"], fixed="$fixed", in="$start", out="$out", delta="$delta", up="$up", down="$down\"
heading=\""bond=["$bond"], fixed="$fixed", delta="$delta", spacing="$spacing"\nin="$start", out="$out", up="$up", down="$down\"

echo $heading > ./$dirname/calculation.dat

################################################################################

#printf "\nnsteps="$nsteps", delta="$delta", spacing="$spacing", in="$start", out="$out", up="$up", down="$down", bond=["$bond"], fixed="$fixed"\n"
printf "\n\n*************************************************************************\n\nSUMMARY\n\n"
printf "Bond: ["$bond"]\n"
printf "Fixed atom: $fixed\n"
echo "Integration plane coordinates"
printf "in = $start  out = $out  up = $up  down = $down \n"
printf "Split into $nsteps slices with width $delta and grid spacing $spacing \n"
printf "Magnetic field direction: $MF \n\n"

printf "\n*************************************************************************\n\n"

xstart=$( awk -v delta=$delta -v start=$start 'BEGIN{printf "%.3f\n", start }' )
xend=$( awk -v delta=$delta -v xstart=$xstart 'BEGIN{printf "%.3f\n", -xstart+delta }' )
xup=$( awk -v delta=$delta -v up=$up 'BEGIN{printf "%.3f\n", up }' )
xdown=$( awk -v delta=$delta -v xup=$xup 'BEGIN{printf "%.3f\n", -xup+delta }' )
string=" s/@start@/$xstart/; s/@end@/$xend/; s/@up@/$xup/; s/@down@/$xdown/"
sed "$string" $dirname/gimic.int > $dirname/gimic.0.inp

printf "\nPerforming a dry run...\n\n"
(cd ./$dirname/ && /wrk/mariavd/gimic/install/bin/gimic --dryrun gimic.0.inp | grep "grid points" )
printf "\n\n"

echo "Do you accept the above parameters? Press [n] to cancel."; read accept
if  [ ! -z $accept ] && [ $accept == "n" ]
then
    exit
fi



echo "Preparing input files..."
for (( i=0; i<$nsteps; i++ ))
do
    xstart=$( awk -v i=$i -v delta=$delta -v start=$start 'BEGIN{printf "%.3f\n", start-delta*i }' )
    xend=$( awk -v delta=$delta -v xstart=$xstart 'BEGIN{printf "%.3f\n", -xstart+delta }' )
    string=" s/@start@/$xstart/; s/@end@/$xend/" 
    sed "$string" $dirname/gimic.int > $dirname/gimic.$i.inp
done
echo "done"

# Submit the calculation

wrkdirname=$(pwd)
wrkdirname=$(echo $wrkdirname/$dirname)
echo "Working directory:"; echo $wrkdirname; echo

parallel=6

echo "How many parallel tasks to execute?"
read parallel

# check if too many parallel tasks are called
if [ $parallel -gt $nsteps ]
then
    $parallel=$($nsteps)
fi

# echo "Running Gimic calculations..."
sbatch --ntasks="$parallel" --job-name="$dirname" /wrk/mariavd/scripts/jobscript "$wrkdirname" "$parallel" "$heading" 
echo


#sleep 2
#squeue -u $USER
#echo

