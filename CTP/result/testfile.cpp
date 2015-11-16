#include <iostream>
#include <string>
#include <fstream>

using namespace std;

int main()
{

	ifstream in;
	ofstream out;

	string inFile = "/home/hujunyu/Desktop/2.txt";
	string outFile = "/home/hujunyu/Desktop/out.txt";

	string s;
	char s2[30];
	char a = 0xff;
	in.open(inFile.data());
	out.open(outFile.data());
	
	in.getline(s2, 20);
	cout << s2[1] << a<< endl;
	out << s2 << endl;
	in.close();
	out.close();

	return 0;
}
