#include <stdio.h>
#include <stdlib.h>

int lookahead;

void match(int terminal, int num) {
    if (lookahead == terminal) {
        lookahead = getchar();
    } else {
        printf("Syntax error at (%c) at (%d)\n", lookahead, num + 1);
        exit(1);
    }
}

int nontermA() {
    int debug = 0;

    int num;
    switch (lookahead) {
        case 'a':
            if (debug) printf("found a\n");
            match('a', num);
            num = 1 + nontermA();
            return num;
        default:
            return 0;
    }
}

int nontermB(int numA) {
    int debug = 0;

    int num;
    switch (lookahead) {
        case 'b':
            if (debug) printf("found b\n");
            match('b', num + numA);
            num = 1 + nontermB(numA);
            return num;
        default:
            return 0;
    }
}

void nontermS() {
    int countA = nontermA();
    int countB = nontermB(countA);
    printf("Number of a's: (%d)\nNumber of b's: (%d)\n", countA, countB);
    match('\n', countA + countB);
}

int main(int argc, char** argv) {
    lookahead = getchar();
    do {
        nontermS();
    } while (lookahead != EOF);
    return 0;
}