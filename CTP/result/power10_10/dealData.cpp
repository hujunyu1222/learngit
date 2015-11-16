#include <iostream>
//#include <io.h>
#include <string>
#include <vector>
#include <fstream>

using namespace std;


int main()
{
	string inpath = "/home/hujunyu/Desktop/TinyOS_test/CTP/result/power10_10/";
	string outpath = "/home/hujunyu/Desktop/TinyOS_test/CTP/result/power10_10/";

	int i, j, k;
	string s1;
	char s2[27];

        ifstream in;
	ofstream out1, out2;

	string inFile = inpath + "twoNodeForward.txt";
	string outFile1 = outpath + "Node1_Foward.txt";
	string outFile2 = outpath + "Node2_Foward.txt";

	in.open(inFile.data());
	out1.open(outFile1.data());
	out2.open(outFile2.data());

	while (getline(in, s1))
	{
		//cout << s1 << endl;
		//cout << s1[36] << s1[37] <<endl;
		if (s1[39] == '1' && s1[40] == '3')
		{
			out1 << s1 << endl;
		}

		if (s1[39] == '1' && s1[40] == '5')
		{
			out2 << s1 << endl;
		}
	}
	in.close();
	out1.close();
	out2.close();


	return 0;
}
