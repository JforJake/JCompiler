
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

// This program takes inputs from the filename in the arguments for the main function and
// processes the lines 1 at a time

int processLine(char str1[]) {	 		// finds the word count of input str1
    int wordCount = 0;
    char* tok;					// create a pointer to a string

    tok = strtok(str1, " \t\n\r");
    if (tok == NULL) {				// if returns 0 if newline is empty
	return wordCount;
    }

    while (tok != NULL) {			// increments word count until tok is NULL
	wordCount++;
	tok = strtok(NULL, " \t\n\r");
    }

    return wordCount;				// returns the number of words on given line str1
}


int main(int argc, char *argv[]) {
    int i;
    char str1[1024];
    int lineCount = 0;
    int wordCount = 0;

    if (argc > 2) {				// if more than 1 command line argument
	printf("Too many arguments!\n");
	printf("Try either file name or no argument\n");
	return -1;				// ends program early
    }
    else if (argc == 1) {			// if no argument given
	for (i = 0; i < 1024; i++) {		// copies 1024 characters from input into str1
	    scanf(str1);
	}

	wordCount += processLine(str1);		// calls processLine();
	lineCount++;
    }
    else {					// if exactly 1 command line argument
	FILE *file1 = NULL;			// creates pointer to file variable
	file1 = fopen(argv[1], "r");		// opens filename from argument line

	if (!file1) {				// if fopen fails
	    fprintf(stderr, "Can not open file\n");//print error code
	    return -1;
	}

	//i = 1;
	fgets(str1, sizeof(str1), file1);
	while (!feof(file1)) {			// runs until end of file
	    wordCount += processLine(str1);
	    lineCount++;			// increments line count whenever processing new line

	    //printf("Word count on line %d: %d\n", i, wordCount);
	    //i++;

	    fgets(str1, sizeof(str1), file1);
	}

	//printf("Successfully read file: %s\n", argv[1]);

	fclose(file1);				// closes file
    }

    printf("%d\t%d\n", wordCount, lineCount);	// final output

    return 0;
}
