#!/bin/bash

# $1 contains path to ham folder
# $2 contains path to spam folder

rspamc $1 > output_ham.txt      # Run Rspamd through both directories and 
rspamc $2 > output_spam.txt		# store the output into respective spam/ham files

grep "Symbol" output_spam.txt | sort | uniq > spam_symbols.txt    # Extract all the unique symbol values for both ham/spam into separate files.
grep "Symbol" output_ham.txt | sort | uniq > ham_symbols.txt      # These files are temporary and will be deleted later by the script

# I want to create an array of all the symbols with positive score values so that
# various statistics calculation becomes easy

awk 'substr($3,2,4)> 0.0001 {print$2}' ham_symbols.txt > positive_symbols.txt       # I have made the comparison with 0.0001 and not with 0 because
awk 'substr($3,2,4)> 0.0001 {print$2}' spam_symbols.txt >> positive_symbols.txt		# comparison with 0 also includes symbols with score = 0 which we 
positive=($(cat positive_symbols.txt | sort | uniq))								# don't want
rm -rf positive_symbols.txt													# delete the temporary file			

# $positive is an array containing all positive scoring symbols from both directories

# I want to create an array of all the symbols with negative score values so that
# various statistics calculation becomes easy

awk 'substr($3,2,4)< 0 {print$2}' ham_symbols.txt > negative_symbols.txt
awk 'substr($3,2,4)< 0 {print$2}' spam_symbols.txt >> negative_symbols.txt
negative=($(cat negative_symbols.txt | sort | uniq))
rm -rf negative_symbols.txt													# delete the temporary file

# $negative is an array containing all negative scoring symbols from both directories

echo STATISTICS > symbol_statistics.txt

# Looping through all the symbols with positive score

for i in "${positive[@]}"
do
	echo >> symbol_statistics.txt
	echo >> symbol_statistics.txt
	hit_rate=0
	false_positive=0

	# For symbols with positive score, false-positive is equal to number of times it scores for ham

	false_positive=$(($false_positive + $(grep $i output_ham.txt | wc -l)))

	# For symbols with positive score value, we count a hit if it scores for our spam folder

	hit_rate=$(($hit_rate + $(grep $i output_spam.txt | wc -l)))
	echo Symbol  :  $i  >> symbol_statistics.txt 
	echo hit_rate : $hit_rate/$(grep $i output_spam.txt output_ham.txt | wc -l) >> symbol_statistics.txt
	echo false_positive  :  $false_positive/$(grep $i output_spam.txt output_ham.txt | wc -l) >> symbol_statistics.txt
	if [ $hit_rate -lt $false_positive ]						# slight check if it's a good symbol or not
	then
		echo Not a Good Symbol >> symbol_statistics.txt
	fi
done

# Looping through all the symbols with negative score

for i in "${negative[@]}"
do
	echo >> symbol_statistics.txt
	echo >> symbol_statistics.txt
	hit_rate=0
	false_positive=0

	# For symbols with negative score, false-positive is equal to number of times it scores for spam

	false_positive=$(($false_positive + $(grep $i output_spam.txt | wc -l)))
	
	# For symbols with negative score value, we count a hit if it scores for our ham folder

	hit_rate=$(($hit_rate + $(grep $i output_ham.txt | wc -l)))
	echo Symbol  :  $i  >> symbol_statistics.txt 
	echo hit_rate : $hit_rate/$(grep $i output_spam.txt output_ham.txt | wc -l) >> symbol_statistics.txt
	echo false_positive  :  $false_positive/$(grep $i output_spam.txt output_ham.txt | wc -l) >> symbol_statistics.txt
	if [ $hit_rate -lt $false_positive ]								# slight check if it's a good symbol or not
	then 
		echo Not a Good Symbol >> symbol_statistics.txt
	fi
done

rm -rf output_spam.txt output_ham.txt ham_symbols.txt spam_symbols.txt				# delete all the temporary files
																					# just keep the symbol_statistics.txt file as output for this script



