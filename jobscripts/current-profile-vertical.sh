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

function userValue()
{
    local __resultVar=$1
    local __varValue="$2"
    local localResult="$2"

     printf  "\nDo you accept $__resultVar=$__varValue bohr?\nPress [n] to change\n"
     read accept;
     if [ ! -z $accept ] && [ $accept == "n" ]
     then
         printf "$__resultVar="; read __varValue
     fi # if centroid calculation not accepted 

eval $__resultVar="'$__varValue'"
}

function calculateRot() {
awk -v a1=$atom1 -v a2=$atom2 -v a3=$atom3 '{
    if (NR == a1+1)
        { 
        a1x = $1;
        a1y = $2;
        a1z = $3;
    };
    if (NR == a2+1)
        { 
            a2x = $1;
            a2y = $2;
            a2z = $3;
        };
    if (NR == a3+1)
        { 
            a3x = $1;
                a3y = $2;
                a3z = $3;
            };
    }

    END {

        bx = (a1x + a2x)/2;
        by = (a1y + a2y)/2;
        bz = (a1z + a2z)/2;

        # Law of cosines: triangle formed between the centre of the bond, atom1 and atom3
        sideA = sqrt( (a1x-bx)*(a1x-bx) + (a1y-by)*(a1y-by) + (a1z-bz)*(a1z-bz)  )
        sideB = sqrt( (a3x-a1x)*(a3x-a1x) + (a3y-a1y)*(a3y-a1y) + (a3z-a1z)*(a3z-a1z)  )
        sideC = sqrt( (a3x-bx)*(a3x-bx) + (a3y-by)*(a3y-by) + (a3z-bz)*(a3z-bz)  )

        #print "Sides:", sideA, sideB, sideC;

        cosBeta = ( sideA*sideA + sideC*sideC - sideB*sideB ) / ( 2*sideA*sideC);
        # print cosBeta;

        # awk does not support acos but acos = atan2(sqrt(1 - x * x))
        beta = atan2(sqrt(1 - cosBeta*cosBeta), cosBeta);
        # print "Beta =", beta;
        betaDeg = beta*57.2957795;
        # print "Beta =", betaDeg, "deg";
        print -(90 - betaDeg);
    }' coord

}

printf "\nStarting current profile analysis\n"
printf "\nUsing atomic units of length\n\n"

echo "Define the bond perpendicular to which to integrate"; echo
echo "Enter the indices of the atoms according to the coord file"
printf "Atom 1:  "; read atom1; 
printf "Atom 2:  "; read atom2
distance=$( awk -v a1="$atom1" -v a2="$atom2" '{ if (NR == a1+1) { x+=$1;y+=$2;z+=$3;}; if (NR == a2+1) {x-=$1;y-=$2;z-=$3} } END{ dist=sqrt(x*x+y*y+z*z); print dist*0.5; }' coord ; )
bond=$atom1","$atom2


echo "Enter the suffix for the directory name"
read suffix
suffix=$(printf _$suffix)
dirname=vertical_profile_$atom1.$atom2$suffix
echo $dirname

#dirname=vertical_profile_$atom1.$atom2
	
# If we are not in the vertical_profile folder, check if it exists. If it did, just go there. If it did not, create it and copy the necessary files
dir=$(pwd | grep "vertical_profile")
#echo $dir
if [ -z $dir ] # if the path does not contain "vertical_profile", $dir is empty, so the directory either does not exist, or we are not inside it
then
    #echo "Currently not in the directory vertical_profile"
    if [ -d $dirname ] 
    then
	printf "\n\n*** Directory already exists.\n\nCalculation parameters:\n"
	grep "bond=\|fixed=\|height=\|width=\|MF=" $dirname/gimic.int  # the = signs are needed, otherwise other words are printed, too
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
    fi # end if vertical_profile_#.#
fi # end if directory vertical_profile_#.# exists or we are inside it

# Coordinates of the centre:
BOND=$(centroid $atom1 $atom2)
Bx=$( echo $BOND | awk '{print $1} ' )
By=$( echo $BOND | awk '{print $2} ' )
Bz=$( echo $BOND | awk '{print $3} ' )

#echo "Bond centre coordinates:"
#printf "("$Bx";"$By";"$Bz")\n"

# Check if there already is an input file
if [ -f $dirname/calculation.dat ] 
then
    fixed=$( sed -n -e 's/^.*fixed=*//p' $dirname/calculation.dat | awk 'BEGIN { FS = "," } ; { print $2 }' )
fi
# If there was not a previous calculation, $fixed will be empty. Ask if it should be changed
if [ ! -z $fixed ] 
then
    printf "\nThe previously selected fixed atom is $fixed.\nPress [n] to change\n"
    read accept
fi
accept="y"
# If the $fixed is empty or the user wants to change it, ask to enter 
if [[ ( -z $fixed ) || ( ! -z $accept  &&  "$accept" == "n" ) ]]
    then 
        printf "\nEnter the index of the fixed atom:\n"
        read fixed
fi

printf "\n\nSTARTING POINT OF THE INTEGRATION\n"
userInp start $start

printf "\nEND POINT OF THE INTEGRATION\n"
out=10
printf "\nDo you accept out=$out bohr?"
userInp out $out

up=10
down=-10
printf "\n\nUPPER AND LOWER BOUNDS OF THE INTEGRATION\n"
userValue up $up
userValue down $down

delta=0.02
printf "\n\nWIDTH OF THE SLICES\n"
userValue delta $delta

nsteps=$( awk -v up=$up -v down=$down -v delta=$delta 'BEGIN{nsteps=(down+up)/delta; if (nsteps > 0) {printf("%d",nsteps)} else {printf("%d",-nsteps);}; }'   )


#Practice has shown that for delta=0.1, the spacing value should be 0.02 in order to have at least 9 Gaussian points per slice
# If the delta is smaller than 0.1, recalculate:
# spacingFactor=$( awk -v delta=$delta 'BEGIN{ printf("%.4f",delta/0.02) }' )    # how many times smaller the chosen delta value is
# spacing=$( awk -v f=$spacingFactor 'BEGIN{ printf("%.3f",0.013*f) }' )
spacingX=$( awk -v delta=$delta 'BEGIN{ f=delta/0.02; printf("%.3f",0.01*f); }' )
spacingY=$( awk -v delta=$delta 'BEGIN{ f=delta/0.02; printf("%.3f",1.20*f); }' )
spacingZ=$( awk -v delta=$delta 'BEGIN{ f=delta/0.02; printf("%.3f",0.01*f); }' )

printf "\n\nSPACING\n"
printf  "\nDo you accept spacing=[$spacingX, $spacingY, $spacingZ]?\nPress [n] to change\n"
read accept;
if [ ! -z $accept ] && [ $accept == "n" ]
then
    printf "spacingX="; read spacingX
    printf "spacingY="; read spacingY
    printf "spacingZ="; read spacingZ
fi

MF=z
userValue MF $MF

rotation=0.0
printf  "\nRotation from the normal to the bond at the bond centre: $rotation degrees. Do you accept?\nPress [n] to modify\n"
read accept;
if [ ! -z $accept ] && [ $accept == "n" ]
then
    printf "Enter the index of the atom, which the plane has to go through: "
    read atom3;
    rotation=$(calculateRot);
    
    printf "Do you accept rotation to $rotation degrees?\nPress [n] to modify\n"
    read accept;
    if [ ! -z $accept ] && [ $accept == "n" ]
    then
        printf "rotation="; read rotation
    fi  
fi


string="s/@bond@/$bond/; s/@fixed@/$fixed/; s/@distance@/$distance/; s/@start@/$start/; s/@end@/$out/; s/@MF@/$MF/; s/@spacingX@/$spacingX/; s/@spacingY@/$spacingY/; s/@spacingZ@/$spacingZ/;  s/@rotation@/$rotation/; "
sed "$string" /hdd/gimic/jobscripts/gimic.int > $dirname/gimic.int

end=$( awk -v delta=$delta -v start=$up 'BEGIN{print delta-up}' ) 

#echo "Enter title:"
#read heading
#heading=\"$heading"\n bond=["$bond"], fixed="$fixed", in="$start", out="$out", delta="$delta", up="$up", down="$down\"
heading=\""bond=[$bond] fixed=$fixed delta=$delta \nspacing=[ $spacingX;$spacingY;$spacingZ] in=$start out=$out \nup=$up down=$down"\"

echo $heading > ./$dirname/calculation.dat

################################################################################

#printf "\nnsteps="$nsteps", delta="$delta", spacing="$spacing", in="$start", out="$out", up="$up", down="$down", bond=["$bond"], fixed="$fixed"\n"
printf "\n\n*****************************************************************************\n\nSUMMARY\n\n"
printf "Bond: ["$bond"]\n"
printf "Fixed atom: $fixed\n"
echo "Integration plane coordinates"
printf "in = $start  out = $out  up = $up  down = $down \n"
printf "Split into $nsteps slices with width $delta and grid spacing [$spacingX; $spacingY; $spacingZ] \n"
printf "Magnetic field direction: $MF \n\n"

printf "\n*****************************************************************************\n\n"

xup=$( awk -v delta=$delta -v up=$up -v down=$down 'BEGIN{printf "%.3f\n", down+delta }' )
xdown=$down

accept="y" 
while [ -z $accept ] 
do
    string=" s/@up@/$xup/; s/@down@/$xdown/; "
    sed "$string" $dirname/gimic.int > $dirname/gimic.0.inp

    printf "\nPerforming a dry run...\n\n"
    (cd ./$dirname/ && gimic --dryrun gimic.0.inp | grep "grid points" )
    printf "\n\n"

    echo "Do you accept the above parameters? Press [n] to modify or [e] to cancel."; read accept
if  [ ! -z $accept ] && [ $accept == "n" ] 
then 
    userValue spacingX $spacingX
    userValue spacingY $spacingY
    userValue spacingZ $spacingZ
elif  [ ! -z $accept ] && [ $accept == "e" ] 
then 
    exit
fi
done

echo "Preparing input files..."
for (( i=0; i<$nsteps; i++ ))
do
    xup=$( awk -v i=$i -v delta=$delta -v up=$up -v down=$down 'BEGIN{printf "%.3f\n", down+delta*(i+1) }' )
    xdown=$( awk -v i=$i -v delta=$delta -v down=$down 'BEGIN{printf "%.3f\n", down+delta*i }' )
#    if [ $smaller -eq 1 ]
#    then
#        tmp=$xstart
#        xstart=$xend
#        xend=$tmp
#    fi
    string=" s/@up@/$xup/; s/@down@/$xdown/"
    sed "$string" $dirname/gimic.int > $dirname/gimic.$i.inp
done    
echo "done"

# Submit the calculation

wrkdir=$(pwd)
wrkdir=$(echo $wrkdir/$dirname)
echo "Working directory:"; echo $wrkdir; echo

echo "Running Gimic calculations..."

filenum=$(ls $wrkdir/*inp | wc -l)
#filenum=$(echo $nsteps)

parallel=4

echo "How many parallel tasks to execute?"
read parallel

# check if too many parallel tasks are called
if [ $parallel -gt $nsteps ]
then
    $parallel=$($nsteps)
fi

# clean up possible previous calculations
rm -rf *dat *eps GIMIC.*

date
echo "Running $parallel out of $filenum GIMIC calculations at a time..."

whole=$( awk -v filenum=$filenum -v parallel=$parallel 'BEGIN{printf "%d\n", filenum/parallel}'  )
remain=$(awk -v whole=$whole -v filenum=$filenum -v parallel=$parallel 'BEGIN{printf "%d\n", (filenum-whole*parallel) }')

completed=0

for ((i=0; i<$whole; i++)) 
do 
    for ((j=0; j<$parallel; j++))
    do  
        index=$(($i+$j*$whole))
        grepstring=""
        if [ -f "$wrkdir/gimic.$index.out" ]
        then
            echo "The file $wrkdir/gimic.$index.out already exists."
            grepstring=$(grep "wall" $wrkdir/gimic.$index.out)
            echo "$grepstring"
        fi

        if [ -z "$grepstring" ]
        then
            cd $wrkdir && gimic gimic.$index.inp > $wrkdir/gimic.$index.out & 
        fi
    done 
    wait
    completed=$(( $completed+$parallel ))
    date
    echo "$completed of $filenum completed"; echo
done

if [[ "$remain" -gt "0" ]]; then
    for ((i=0; i<$remain; i++))
    do  
        (cd $wrkdir && gimic $wrkdir/gimic.$(($parallel*$whole+$i)).inp >  $wrkdir/gimic.$(($parallel*$whole+$i)).out &) 
    done
fi
echo "$filenum of $filenum completed"


#    cd $wrkdir && gimic gimic.$index.inp > $wrkdir/gimic.$index.out



rm -rf GIMIC* 

###################################################################################

echo "Calculating the gradient..."

cat /dev/null > $wrkdir/paratropic.dat #delete if it already exists
cat /dev/null > $wrkdir/diatropic.dat
cat /dev/null > $wrkdir/current.dat

#out=$(grep out= $wrkdir/gimic.0.inp | grep -o -E '[0-9.]+')
#start=$(grep in= $wrkdir/gimic.0.inp | grep -o -E '[0-9.]+')
#delta=$( awk -v out=$out -v start=$start 'BEGIN{ value=out-start; delta=(value<0?-value:value); print delta }' )

for (( i=0; i<$filenum; i++ ))
do
    grep -A 2 "Induced current" $wrkdir/gimic.$i.out | awk -v wrkdir=$wrkdir '{ dia=sprintf("%s/diatropic.dat",wrkdir); para=sprintf("%s/paratropic.dat",wrkdir); if (NR == 2) printf("% f\n", $5) >> dia; else if (NR == 3) printf("% f\n", $5) >> para; }'
    grep "Induced current (nA/T)" $wrkdir/gimic.$i.out | awk -v i=$i -v down=$down -v delta=$delta -v wrkdir=$wrkdir '{ out=sprintf("%s/current.dat",wrkdir); printf("%5.2f\t% f\n", i*delta,$5) >> out; }'
done

paste $wrkdir/current.dat $wrkdir/diatropic.dat $wrkdir/paratropic.dat > $wrkdir/current_profile.dat
rm -f $wrkdir/paratropic.dat $wrkdir/diatropic.dat $wrkdir/current.dat

printf "\nData saved in current_profile.dat\n\n"

gnuplot << EOF                                                                                   

# diatropic (green)
set style line 1 lt 1 lw 5 lc rgb "#007F00" 
# paratropic (blue)
set style line 2 lt 3 lw 5 lc rgb "#1E46FF"
# vertical lines (cyan)
set style line 3 lt 1 lw 2 lc rgb "#00DCFF"
# vertical zero line
set style line 4 lt 1 lw 5 lc rgb "#000000" 

set format x "%5.2f"
set format y "%5.2f"
unset label
set xlabel "Distance [bohr]"
set ylabel "dJ/dx [nA/T / bohr]"

set terminal postscript eps enhanced color 'Helvetica' 22

set output "$wrkdir/$dirname-current-profile.eps"
set title $heading
plot "$wrkdir/current_profile.dat" u 1:2 w l lc 0 lw 2 notitle
set output "$wrkdir/$dirname-current-dia-para.eps"
set title $heading
plot "$wrkdir/current_profile.dat" u 1:3 w l ls 1 title "Diatropic", "$wrkdir/current_profile.dat" u 1:4 w l ls 2 title "Paratropic"

EOF

echo "Plots generated at "
echo $wrkdir/$dirname-current-profile.eps
echo $wrkdir/$dirname-current-dia-para.eps
echo

#######################################################################
# Find the zeroes on the current profile plot

/hdd/gimic/jobscripts/crit_pts.sh $dirname > $wrkdir/profile-points.out

cat $wrkdir/profile-points.out

#######################################################################

echo