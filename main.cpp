#include <iostream>
#include <fstream>
#include <vector>
#include <cstdio>
#include <sstream>
#include <cstdlib>
#include <string>

using namespace std;
const int REGCARET = 0xFF;
const int REGL     = 0xFD;
const int REGR     = 0xFE;

unsigned int registers[0x100];

typedef struct
{
    vector<string> lines;
    string filename;
} filesholder_t;

vector<filesholder_t>  filesholder;

vector<string> exec(string cmd) 
{
    vector<string> result;
    
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) return result;
    char buffer[1024];
    string strbuff = "";
    while(!feof(pipe)) 
    {
    	if(fgets(buffer, 1024, pipe) != NULL)
    	{
    	    strbuff = "";
    	    strbuff += buffer;
    	    strbuff.erase(strbuff.find_last_not_of("\n\r") + 1);
    	    result.push_back(strbuff);
    	}
    }
    pclose(pipe);
    return result;
}

std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}

void processfile(std::string filename, int deepness);
int findfileinholder(string command);

void initregisters(uint value)
{
    cout << "# Creating registers" << endl;
    for (int i = 0; i < 0x100; i++)
        registers[i] = value;
}

void outputregisters()
{
    cout << "# Creating output" << endl;
    FILE *f = fopen("output.txt", "w");
    if (f == NULL)
    {
        printf("Error opening file!\n");
        exit(1);
    }
    
    for (int i = 0; i < 0x100; i++)
    {
        fprintf(f, "%02X: %08X ", i, registers[i]);
        if (i % 8 == 7)
            fprintf(f, "\n");
    }
    
    fclose(f);
}

void processcommand(std::string command, std::string lvalue, std::string rvalue, int deepness)
{
    if (command == "MOV")
    {
        if (lvalue.substr(0, 6) == "REGIST")
        {
            int lnum = strtol(lvalue.substr(6, 2).c_str(), 0, 16);
            if (rvalue.substr(0, 6) == "REGIST")
            {
                int rnum = strtol(rvalue.substr(6, 2).c_str(), 0, 16);
                registers[lnum] = registers[rnum];
            }
            else
            {
                // strtol limitation fix
                uint left = strtol(rvalue.substr(0, 4).c_str(), 0, 16);
                uint rght = strtol(rvalue.substr(4, 4).c_str(), 0, 16);            
                registers[lnum] = (left << 16) | rght;
            }
        }
        else
        {
            cout << "ERR: LValue can't be a number" << endl;
            exit(2);
        }
    }
    else if (command == "SHL")
    {
        if (lvalue.substr(0, 6) == "REGIST")
        {
            int lnum = strtol(lvalue.substr(6, 2).c_str(), 0, 16);
            if (rvalue.substr(0, 6) == "REGIST")
            {
                int rnum = strtol(rvalue.substr(6, 2).c_str(), 0, 16);
                registers[lnum] <<= registers[rnum];
                registers[lnum] &= 0xFFFFFFFFU;
            }
            else
            {
                registers[lnum] <<= strtol(rvalue.c_str(), 0, 16);
                registers[lnum] &= 0xFFFFFFFFU;
            }
        }
        else
        {
            cout << "ERR: LValue can't be a number" << endl;
            exit(2);
        }
    }
    else if (command == "SHR")
    {
        if (lvalue.substr(0, 6) == "REGIST")
        {
            int lnum = strtol(lvalue.substr(6, 2).c_str(), 0, 16);
            if (rvalue.substr(0, 6) == "REGIST")
            {
                int rnum = strtol(rvalue.substr(6, 2).c_str(), 0, 16);
                registers[lnum] >>= registers[rnum];
                registers[lnum] &= 0xFFFFFFFFU;
            }
            else
            {
                registers[lnum] >>= strtol(rvalue.c_str(), 0, 16);
                registers[lnum] &= 0xFFFFFFFFU;
            }
        }
        else
        {
            cout << "ERR: LValue can't be a number" << endl;
            exit(2);
        }
    }
    else if (command == "NOR")
    {
        if (lvalue.substr(0, 6) == "REGIST")
        {
            int lnum = strtol(lvalue.substr(6, 2).c_str(), 0, 16);
            if (rvalue.substr(0, 6) == "REGIST")
            {
                int rnum = strtol(rvalue.substr(6, 2).c_str(), 0, 16);
                registers[lnum] = ~(registers[rnum] | registers[lnum]);
                registers[lnum] &= 0xFFFFFFFFU;
            }
            else
            {
                registers[lnum] = ~(strtol(rvalue.c_str(), 0, 16) | registers[lnum]);
                registers[lnum] &= 0xFFFFFFFFU;
            }
        }
        else
        {
            cout << "ERR: LValue can't be a number" << endl;
            exit(2);
        }
    }
    else if (command == "NOP")
    {
        
    }
    else if ( ((command[0] >= 'A') && (command[0] <= 'Z')) &&
             (((command[1] >= 'A') && (command[1] <= 'Z')) || 
              ((command[1] >= '0') && (command[1] <= '9'))) &&
             (((command[2] >= 'A') && (command[2] <= 'Z')) || 
              ((command[2] >= '0') && (command[2] <= '9'))))
    {
        if (lvalue.size() > 0)
        {
            if (lvalue.substr(0, 6) == "REGIST")
            {
                int lnum = strtol(lvalue.substr(6, 2).c_str(), 0, 16);
                registers[REGL] = registers[lnum];
                registers[REGL] &= 0xFFFFFFFFU;
            }
            else
            {
                registers[REGL] = strtol(lvalue.c_str(), 0, 16);
                registers[REGL] &= 0xFFFFFFFFU;
            }
        }
        if (rvalue.size() > 0)
        {
            if (rvalue.substr(0, 6) == "REGIST")
            {
                int rnum = strtol(rvalue.substr(6, 2).c_str(), 0, 16);
                registers[REGR] = registers[rnum];
                registers[REGR] &= 0xFFFFFFFFU;
            }
            else
            {
                registers[REGR] = strtol(rvalue.c_str(), 0, 16);
                registers[REGR] &= 0xFFFFFFFFU;
            }
        }
        
        uint oldcaret = registers[REGCARET];
        processfile(command, deepness + 1);
        registers[REGCARET] = oldcaret;
    }
    else if (command == "#")
    {
        
    }
    else if (command == "##")
    {
        
    }
    else if (command == "")
    {
    
    }
    else
    {
         cout << "ERR: Unknown command: " << command << endl;
         exit(2);
    }
}

void processfile(std::string filename, int deepness)
{
    string spacebuf;
    for (int i = 0; i < deepness; i++)
        spacebuf += " ";
    cout << spacebuf << filename << endl;
    
    int findex = findfileinholder(filename);
    if (findex < 0)
    {
        cout << "ERR: Can't find file: " << filename << endl;
        exit(2);
    }
    
    registers[REGCARET] = 0;
    
    while (filesholder[findex].lines.size() > registers[REGCARET])
    {
        string line;
        
        line = filesholder[findex].lines[registers[REGCARET]];
              
        vector<string> x;
        x.clear();
        split(line, ' ', x);
 
        while (x.size() < 3)
        {
            x.push_back("");
        }
        
        processcommand(x[0], x[1], x[2], deepness);   
            
        registers[REGCARET]++;
    }
}

void loadfile(string filename)
{
    filesholder_t fh;
    fh.filename = exec("basename " + filename + " .aic")[0];
    
    string line;
    ifstream file(filename.c_str());
    if (file.is_open())
    {
        while (getline(file, line))
        {
            fh.lines.push_back(line);
        }
        file.close();
    }
    else
    {
        cout << "ERR: Can't open file: " << filename << endl;
        exit(2);
    }
    
    filesholder.push_back(fh);
}

int findfileinholder(string command)
{
    for (int i = 0; i < filesholder.size(); i++)
    {
        if (command == filesholder[i].filename)
            return i;
    }
    return -1;
}

void initcommands(string filename)
{
    string combuffer = "find ./sys ./usr -type f && echo """;
    combuffer.append(filename);
    combuffer.append("""");
    
    vector<string> filelist = exec(combuffer);
    for (int i = 0; i < filelist.size(); i++)
    {
        loadfile(filelist[i]);
    }
}

int main(int argc, char * argv[])
{
    initregisters(0);    
    initcommands("test.aic");
    processfile("test", 0);

   
    outputregisters();
   
    return 0;
}

