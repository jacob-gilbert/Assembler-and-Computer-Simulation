#ifndef __PROJECT1_CPP__
#define __PROJECT1_CPP__

#include "project1.h"
#include <vector>
#include <string>
#include <unordered_map>
#include <iostream>
#include <sstream>
#include <fstream>

int main(int argc, char* argv[]) {
    if (argc < 4) // Checks that at least 3 arguments are given in command line
    {
        std::cerr << "Expected Usage:\n ./assemble infile1.asm infile2.asm ... infilek.asm staticmem_outfile.bin instructions_outfile.bin\n" << std::endl;
        exit(1);
    }
    //Prepare output files
    std::ofstream inst_outfile, static_outfile;
    static_outfile.open(argv[argc - 2], std::ios::binary);
    inst_outfile.open(argv[argc - 1], std::ios::binary);
    std::vector<std::string> instructions;
    std::vector<std::string> data;

    /**
     * Phase 1:
     * Read all instructions, clean them of comments and whitespace DONE
     * TODO: Determine the numbers for all static memory labels
     * (measured in bytes starting at 0)
     * TODO: Determine the line numbers of all instruction line labels
     * (measured in instructions) starting at 0
    */

    bool dataSectionStarted = false; // indicator for when things should be stored as data
    int staticMemorySize = 0; // tracks the memory static data should allocate
    //For each input file:
    for (int i = 1; i < argc - 2; i++) {
        std::ifstream infile(argv[i]); //  open the input file for reading
        if (!infile) { // if file can't be opened, need to let the user know
            std::cerr << "Error: could not open file: " << argv[i] << std::endl;
            exit(1);
        }

        std::string str;
        while (getline(infile, str)){ //Read a line from the file
            str = clean(str); // remove comments, leading and trailing whitespace
            if (str == "") { //Ignore empty lines
                continue;
            }
            // TODO instructions.push_back(str) will need to change for labels - done
            if (str == ".data") { // signifies the static memory section
                dataSectionStarted = true;
                continue;
            }

            if (str == ".text") {
                dataSectionStarted = false; // now want to add to instructions
                continue;
            }

            if (str == ".align 2") {
                continue;
            }

            if (str == ".globl main") {
                continue;
            }
            if (dataSectionStarted) { // true when ".data" has been found
                std::vector<std::string> terms = split(str, WHITESPACE+",()");
                staticMemoryMap[terms[0].substr(0, terms[0].length() - 1)] = staticMemorySize; // storing where in static memory the label starts at
                staticMemorySize += (terms.size() - 2) * 4; // ignore label and .word when considering size
                data.push_back(str);
            }

            else if (str.back() == ':') {
                std::string label = str.substr(0, str.length() - 1); // extract label name
                label_map[label] = instructions.size(); // store the label with its line number
            } 

            else {
                instructions.push_back(str); // store the instruction normally
            }
        }
        infile.close();
    }

    // For project checkpoint 5 adding End_Static_Mem to the static label map
    staticMemoryMap["End_Static_Mem"] = staticMemorySize;


    /** Phase 2
     * Process all static memory, output to static memory file
     * TODO: All of this
     */

    for (std::string dt : data) {
        std::vector<std::string> terms = split(dt, WHITESPACE+",()");
        for (int i = 2; i < terms.size(); i++) { // skip name and .word
            auto it = label_map.find(terms[i]); // checking if it is a label
            if (it != label_map.end()) { // if it is a label
                write_binary(label_map[terms[i]] * 4, static_outfile); // multiply by 4 because there are 4 bytes for every line up to the label
            }
            else {
                write_binary(std::stoi(terms[i]), static_outfile); // just a number
            }
        }
    }


    /** Phase 3
     * Process all instructions, output to instruction memory file
     * TODO: Almost all of this, it only works for adds
     */
    int line_count = 0;
    for(std::string inst : instructions) {
        std::vector<std::string> terms = split(inst, WHITESPACE+",()");
        std::string inst_type = terms[0];
        if (inst_type == "add") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 32);
            write_binary(encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 32),inst_outfile);
        }

        else if (inst_type == "addi") {
            int result = encode_Itype(8, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "la") {
            int result = encode_Itype(8, registers["$0"], registers[terms[1]], staticMemoryMap[terms[2]]);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "sub") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 34);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "mult") {
            int result = encode_Rtype(0,registers[terms[1]], registers[terms[2]], 0, 0, 24);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "div") {
            int result = encode_Rtype(0,registers[terms[1]], registers[terms[2]], 0, 0, 26);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "mfhi") {
            int result = encode_Rtype(0,0,0, registers[terms[1]], 0, 16);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "mflo") {
            int result = encode_Rtype(0,0,0, registers[terms[1]], 0, 18);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "sll") {
            int result = encode_Rtype(0,0, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]), 0);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "srl") {
            int result = encode_Rtype(0,0, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]), 2);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "slt") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 42);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "syscall") {
            write_binary(53260,inst_outfile);
        }

        else if (inst_type == "lw") {
            int result = encode_Itype(35, registers[terms[3]], registers[terms[1]], std::stoi(terms[2]));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "sw") {
            int result = encode_Itype(43, registers[terms[3]], registers[terms[1]], std::stoi(terms[2]));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "beq") {
            int result = encode_Itype(4, registers[terms[1]], registers[terms[2]], label_map[terms[3]] - (line_count + 1));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "bne") {
            int result = encode_Itype(5, registers[terms[1]], registers[terms[2]], label_map[terms[3]] - (line_count + 1));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "j") {
            int result = encode_Jtype(2, label_map[terms[1]]);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "jal") {
            int result = encode_Jtype(3, label_map[terms[1]]);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "jalr") {
            if (terms.size() == 3) {
                int result = encode_Rtype(0,registers[terms[1]], 0, registers[terms[2]], 0, 9);
            }
            int result = encode_Rtype(0,registers[terms[1]], 0, registers["$31"], 0, 9);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "jr") {
            int result = encode_Rtype(0,registers[terms[1]], 0, 0, 0, 8);
            write_binary(result,inst_outfile);
        }


        // Challenge Instructions
        else if (inst_type == "li") { // basically an addi
            int result = encode_Itype(8, 0, registers[terms[1]], std::stoi(terms[2]));
            write_binary(result,inst_outfile);
        }

        if (inst_type == "move") { // basically an add
            int result = encode_Rtype(0, registers[terms[2]], 0, registers[terms[1]], 0, 32);
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "bge") {
            // bge rs rt label
            // slt $at rs rt
            // beq $at $0 label

            int result = encode_Rtype(0,registers[terms[1]], registers[terms[2]], registers["$at"], 0, 42); // slt
            write_binary(result,inst_outfile);

            result = encode_Itype(4, registers["$at"], registers["$0"], label_map[terms[3]] - (line_count + 1)); // beq
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "bgt") {
            // bgt rs rt label
            // slt $at, rt, rs
            // bne $at $0 label

            int result = encode_Rtype(0,registers[terms[2]], registers[terms[1]], registers["$at"], 0, 42); // slt
            write_binary(result,inst_outfile);

            result = encode_Itype(5, registers["$at"], registers["$0"], label_map[terms[3]] - (line_count + 1)); // bne
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "ble") {
            // bge rs rt label
            // slt $at rt rs
            // beq $at $0 label

            int result = encode_Rtype(0,registers[terms[2]], registers[terms[1]], registers["$at"], 0, 42); // slt
            write_binary(result,inst_outfile);

            result = encode_Itype(4, registers["$at"], registers["$0"], label_map[terms[3]] - (line_count + 1)); // beq
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "blt") {
            // bgt rs rt label
            // slt $at, rs, rt
            // bne $at $0 label

            int result = encode_Rtype(0,registers[terms[1]], registers[terms[2]], registers["$at"], 0, 42); // slt
            write_binary(result,inst_outfile);

            result = encode_Itype(5, registers["$at"], registers["$0"], label_map[terms[3]] - (line_count + 1)); // bne
            write_binary(result,inst_outfile);
        }

        if (inst_type == "and") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 36);
            write_binary(result ,inst_outfile);
        }

        if (inst_type == "or") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 37);
            write_binary(result ,inst_outfile);
        }

        if (inst_type == "xor") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 38);
            write_binary(result ,inst_outfile);
        }

        if (inst_type == "nor") {
            int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 39);
            write_binary(result ,inst_outfile);
        }

        else if (inst_type == "andi") {
            int result = encode_Itype(12, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "ori") {
            int result = encode_Itype(13, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "xori") {
            int result = encode_Itype(14, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]));
            write_binary(result,inst_outfile);
        }

        else if (inst_type == "lui") {
            int result = encode_Itype(15, 0, registers[terms[1]], std::stoi(terms[3]));
            write_binary(result,inst_outfile);
        }

        // seq rdest, rsrc1, rsrc2
        // Set register rdest to 1 if register rsrc1 equals rsrc2, and to 0 otherwise
        //else if (inst_type == "slt") {
        //    int result = encode_Rtype(0,registers[terms[2]], registers[terms[3]], registers[terms[1]], 0, 42);
        //    write_binary(result,inst_outfile);
        //}

        //else if (inst_type == "abs") {
        //    int result = encode_Itype(8, registers[terms[2]], registers[terms[1]], std::stoi(terms[3]));
        //    write_binary(result,inst_outfile);
        //}

        line_count++;
    }

    /**
    std::cout << "Label Map Contents:" << std::endl;
    for (const auto& pair : label_map) {
        std::cout << "Label: " << pair.first << ", Instruction Index: " << pair.second << std::endl;
    }

    std::cout << "Static Memory Map Contents:" << std::endl;
    for (const auto& pair : staticMemoryMap) {
        std::cout << "Label: " << pair.first << ", Memory Size: " << pair.second << std::endl;
    } */
}

#endif
