#include <iostream>
#include <fstream>
#include <string>

using namespace  std;

int main()
{
	string inpath = "/home/hujunyu/Desktop/TinyOS_test/CTP/result/power31_10/";
	string outpath = "/home/hujunyu/Desktop/TinyOS_test/CTP/result/power31_10/";

	int i=0, j=0, k;
	string s1, s2;

	int count1, count2;
	char c45, c46;
	char temp1, temp2;

	ifstream in1, in2;
	ofstream out1, out2;

	string inFile1 = inpath + "Node1_Foward.txt";
	string inFile2 = inpath + "Node2_Foward.txt";

	string outFile1 = outpath + "Node1_PDR.txt";
	string outFile2 = outpath + "Node2_PDR.txt";

	in1.open(inFile1.data());
	in2.open(inFile2.data());

	out1.open(outFile1.data());
	out2.open(outFile2.data());
	
	count1 = 0;
	count2 = 0;
	getline(in1, s1);
	temp1 = s1[46];
	while (getline(in1, s1))
	{
		i++;
		c46 = s1[46];
		if(c46 == temp1)
		{
			count1++;
		}

		if(i % 3 ==0)
		{
			out1 << i << "," << 1- count1*1.0/i << endl;
		}
	}

	out1 << i <<"," <<1- count1*1.0/i << endl;

	getline(in2, s2);
	temp2 = s2[46];
	while (getline(in2, s2))
	{
		j++;
		c46 = s2[46];
		if(c46 == temp2)
		{
			count2++;
		}

		if(j % 3 == 0)
		{
			out2 << j << "," << 1- count2*1.0/j <<endl;
		}
	}

	out2 << j << "," << 1- count2*1.0/j <<endl;

	in1.close();
	in2.close();
	out1.close();
	out2.close();
	return 0;
}
