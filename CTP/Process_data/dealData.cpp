#include <iostream>
#include <string>
#include <vector>
#include <fstream>

using namespace std;

int main (int argc, char* argv[])
{
	string inpath = "./";
	string outpath = "./";

	int i, j, k;
	string s1;
	char s2[1000];

	ifstream in;
	ofstream out;


	string inFile = inpath + argv[1];
	string outFile = outpath + argv[2];
	
	cout << inFile << endl;
	cout << outFile << endl;

	in.open(inFile.data());
	if(!in)
	{
		cout<<"failed to open the file"<<endl;
	}
	out.open(outFile.data());

	while ( getline(in, s1) )
	{
		if (s1[39] == '1' && s1[40] == '9')
		{
			out << s1 << endl;
		}
	}

	in.close();
	out.close();

	return 0;
}
