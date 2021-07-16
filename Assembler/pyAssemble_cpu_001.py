# cpu_001 Assembler
# Assemble code for CPU
# 
# CPU is at
# 	https://github.com/douggilliland/Design_A_CPU/tree/main
#
# Input File
#	File named: fileName.csv
# 	Input file is tightly constrained in CSV file
# 	Input File Header has to be -
#		['LABEL', 'OPCODE', 'REG_LABEL', 'OFFSET_ADDR', 'COMMENT']
# 
# Memory Map File
#	Optional
#	File named: fileName_MMAP.csv
#	Memory map file Header has to be -
#		['IO_ADDR','DIR','MNEUMONIC']
#	IO_ADDR = 0XNN
#	DIR = R, W, or RW
#	Ex: ['0X00','R','LED_RD']
#
# Output files
# 	.mif file - Quartus II ROM Memory Initialization File
#	.lst file - Listing file (with addresses)
#
# Assembler opcodes
#	LRI - Load a register with an immediate value (byte)
#	SRL - Shift register left
#	SRR - Shift register right
#	RRL - Rotate register left
#	RRR - Rotate register right
#	IOW - Write a register to an I/O address
#	IOR - Read an I/O address to a register
#	ORI - OR a register with an immediate value
#	ARI - AND a register with an immediate value
#	JSR - Jump to a subroutine (single level only)
#	RTS - Return from subroutine
#	BEZ - Branch if equal to zero
#	BNZ - Branch if not equal to zero
#	JMP - Jump to an address
#
# Assembler Psuedo-opcodes
#	NOP - No operation
#	HLT - Halt (Jump to self)
#	BEQ - Branch if equal (same as BEZ)
#	BNE - Branch if not equal (Aame as BNZ)
#
# Error Messages
#	Error messages are pretty rudimentary.
#	Error messages are printed to the command window.
#	The line with the error is printed as a list of the line.
#	Missing labels are presented as a message.
# 	Only one error at a time is presented.
#

import csv
import string
import os
import sys
from sys import version_info

import time
from datetime import date

from dgProgDefaultsTk import *
from dgReadCSVtoListTk import *
from dgWriteListtoCSVTk import *

from tkinter import filedialog
from tkinter import *
from tkinter import messagebox

defaultPath = '.'

class ControlClass:
	"""Methods to read tindie or Kickstarter files and write out USPS and PayPal lists.
	"""
	def doConvert(self):
		"""The code that calls the other code
		"""
		global defaultPath
		defaultParmsClass = HandleDefault()
		defaultParmsClass.initDefaults()
		defaultPath = defaultParmsClass.getKeyVal('DEFAULT_PATH')
		# print '(doConvert): defaultPath',defaultPath
		myCSVFileReadClass = ReadCSVtoList()	# instantiate the class
		myCSVFileReadClass.setVerboseMode(False)	# turn on verbose mode until all is working 
		myCSVFileReadClass.setUseSnifferFlag(True)
		doneReading = False
		inList = myCSVFileReadClass.findOpenReadCSV(defaultPath,'Select ASM (CSV) File')	# read in TSV into list
		if inList == []:
			errorDialog("doConvert): No file selected")
			return
		defaultPath = myCSVFileReadClass.getLastPath()
		defaultParmsClass.storeKeyValuePair('DEFAULT_PATH',defaultPath)
		if inList[0] != ['LABEL', 'OPCODE', 'REG_LABEL', 'OFFSET_ADDR', 'COMMENT','V3.0.0']:
			if len(inList[0]) < 6:
				errorDialog('Header does not match expected values\nSee command window\nProbably needs the version number added to the final column header')
			elif inList[0][5] != 'V3.0.0':
				errorDialog('Header does not match expected values\nSee command window\nCore rev s/b V3.0.0Should be ')
			else:
				errorDialog('Header does not match expected values\nSee command window')
			print('header :',inList[0])
			assert False,'header does not match expected values'
		else:
			print('header ok')
		inFileName = myCSVFileReadClass.getLastPathFileName()
		memMapList = []
		memMapFileName = inFileName[0:-4] + '_MMAP.csv'
		if os.path.isfile(memMapFileName):
			print('Memory map exists')
			memMapList = myCSVFileReadClass.readInCSV(memMapFileName)
			print('memMapList',memMapList)
		print('memMapFileName',memMapFileName)
		progCounter = 0
		labelsList = {}
		for row in inList[1:]:
			if row[0] != '':
				labelsList[row[0]] = progCounter
			if row[1] == 'HLT':
				labelName = 'HLT_' + str(progCounter)
				labelsList[labelName] = progCounter
			progCounter += 1
		print('labelsList',labelsList)
		program = []
		progCounter = 0
		for row in inList[1:]:
			# print(row)
			row[1] = row[1].upper()
			if row[1] != '':
				if row[1] == 'SLL':
					if row[3] != '0X01':
						assert False,'Only supports single shift'
					vecStr = '0x3'
					vecStr += row[2][-1]
					vecStr += "01"
					program.append(vecStr)
				elif row[1] == 'SLR':
					if row[3] != '0X01':
						assert False,'Only supports single shift'
					vecStr = '0x3'
					vecStr += row[2][-1]
					vecStr += "81"
					program.append(vecStr)
				elif row[1] == 'SAL':
					if row[3] != '0X01':
						assert False,'Only supports single shift'
					vecStr = '0x3'
					vecStr += row[2][-1]
					vecStr += "21"
					program.append(vecStr)
				elif row[1] == 'SAR':
					if row[3] != '0X01':
						assert False,'Only supports single shift'
					vecStr = '0x3'
					vecStr += row[2][-1]
					vecStr += "A1"
					program.append(vecStr)
				elif row[1] == 'RRL':
					if row[3] != '0X01':
						assert False,'Only supports single shift'
					vecStr = '0x3'
					vecStr += row[2][-1]
					vecStr += "41"
					program.append(vecStr)
				elif row[1] == 'RRR':
					if row[3] != '0X01':
						assert False,'Only supports single shift'
					vecStr = '0x3'
					vecStr += row[2][-1]
					vecStr += "C1"
					program.append(vecStr)
				elif row[1] == 'RTS':
					vecStr = '0x3008'
					program.append(vecStr) 
				elif row[1] == 'LRI':
					vecStr = '0x4'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'CMP':
					vecStr = '0x5'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'IOR':
					vecStr = '0x6'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'IOW':
					vecStr = '0x7'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'XRI':
					vecStr = '0x8'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'ORI':
					vecStr = '0x9'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'NOP':	# Psuedo-Op
					vecStr = '0x9800'  # ORI Reg8,0x00	
					program.append(vecStr)
				elif row[1] == 'ARI':
					vecStr = '0xA'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'ADI':
					vecStr = '0xB'
					vecStr += row[2][-1]
					vecStr += row[3][-2:]
					program.append(vecStr)
				elif row[1] == 'HLT':
					vecStr = '0xB'
					labelName = 'HLT_' + str(progCounter)
					distance = labelsList[labelName]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				elif row[1] == 'JSR':
					vecStr = '0xC'
					distance = labelsList[row[2]]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				elif row[1] == 'JMP':
					vecStr = '0xD'
					distance = labelsList[row[2]]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				elif row[1] == 'BEZ':
					vecStr = '0xE'
					distance = labelsList[row[2]]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				elif row[1] == 'BEQ':
					vecStr = '0xE'
					distance = labelsList[row[2]]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				elif row[1] == 'BNZ':
					vecStr = '0xF'
					distance = labelsList[row[2]]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				elif row[1] == 'BNE':
					vecStr = '0xF'
					distance = labelsList[row[2]]
					distStr = self.calcOffsetString(distance)
					vecStr += distStr
					program.append(vecStr)
				else:
					errorDialog('Bad instruction.\nSee command window') 
					print('bad instr', row)
					assert False,'bad instr'
				progCounter += 1
		# print('program',program)
		# Create the list file
		annotatedSource = []
		progOffset = 0
		for rowOffset in range(len(inList)-1):
			# print(inList[rowOffset])
			annRow = []
			annRow.append(inList[rowOffset+1][0])
			# print('progOffset',progOffset)
			# Add copcode to listing
			if inList[rowOffset+1][1] != '':
				annRow.append(program[progOffset])
				progOffset += 1
			else:
				annRow.append('')
			annRow.append(inList[rowOffset+1][1])
			annRow.append(inList[rowOffset+1][2])
			annRow.append(inList[rowOffset+1][3])
			annRow.append(inList[rowOffset+1][4])
			#print(annRow)
			annotatedSource.append(annRow)		
		print('inFileName',inFileName)
		self.outStuff(inFileName,annotatedSource,memMapList)
		infoBox("Complete")
		
	def calcOffsetString(self,distanceInt):
		dresultStr = ''
		if distanceInt < 0:
			distanceInt = (distanceInt ^ 4095) + 1
		distStr = hex(distanceInt).upper()
		if distStr[0] == '-':	# -0xffe
			if len(distStr) == 6:
				return distStr[3:]
			elif len(distStr) == 5:
				return '0' + distStr[3:]
			elif len(distStr) == 4:
				return '00' + distStr[3:]
		else:	#0x000
			if len(distStr) == 5:
				return distStr[2:]
			elif len(distStr) == 4:
				return '0' + distStr[2:]
			elif len(distStr) == 3:
				return '00' + distStr[2:]
		# print('distance =',distStr)
		return distStr
	
	def outStuff(self,inFileName,sourceFile,memMapList):
		"""
		[['LABEL', 'OPCODE', 'VAL4', 'VAL8', 'COMMENT'], ['INIT', 'NOP', '', '', ''], ['', 'LRI', '0X00', '0X01', 'LOAD START CMD'], ['', 'LRI', '0X01', '0X40', 'LOAD SLAVE ADDR<<1, WRITE'], ['', 'LRI', '0X02', '0X00', 'LOAD IDLE CMD'], ['', 'LRI', '0X03', '0X00', 'LOAD IODIRA REGISTER_OFFSET'], ['', 'LRI', '0X04', '0XFF', 'LOAD IODIRA_ALL_INS'], ['', 'IOW', '0X00', '0X00', 'ISSUE START CMD'], ['', 'IOW', '0X01', '0X00', 'ISSUE SLAVE ADDR<<1, WRITE'], ['', 'IOW', '0X02', '0X00', 'ISSUE IDLE CMD'], ['', 'IOW', '0X03', '0X00', 'ISSUE IODIRA REGISTER_OFFSET'], ['', 'IOW', '0X04', '0X00', 'ISSUE IODIRA_ALL_INS'], ['LDST000', 'IOR', '0X05', '0X00', 'READ STATUS'], ['', 'ARI', '0X05', '0X01', 'BUSY BIT'], ['', 'BNZ', '', 'LDST000', 'LOOP UNTIL NOT BUSY'], ['SELF', 'JMP', 'SELF', '', '']]
		"""
		outFilePathName = inFileName[0:-4] + '.mif'
		print('outFilePathName',outFilePathName)
		# for row in sourceFile:
			# print(row)
		outList = []
		outStr = '-- File: ' + outFilePathName
		outList.append(outStr)
		outList.append('-- Generated by pyAssemble_cpu_001.py')
		outList.append('-- ')
		outLen = 0
		for row in sourceFile:
			if row[1] != '':
				outLen += 1
		outStr = 'DEPTH = '+ str(outLen) + ';'
		outList.append(outStr)
		outList.append('WIDTH = 16;')
		outList.append('ADDRESS_RADIX = DEC;')
		outList.append('DATA_RADIX = HEX;')
		outList.append('CONTENT BEGIN')
		lineCount = 0
		addrCount = 0
		outStr = ''
		# print('outList',outList)
#		assert False,'stop'
		for row in sourceFile:
			if row[1] != '':
				if lineCount == 0:
					outStr += str(addrCount)
					outStr += ': '
				outStr += row[1][2:]
				if lineCount < 7:
					outStr += ' '
				lineCount += 1
				addrCount += 1	
				if lineCount == 8:
					lineCount = 0
					outStr += ';'
					outList.append(outStr)
					outStr = ''
		if outStr != '':
			outStr = outStr[0:-1]
			outStr += ';'
			outList.append(outStr)
		
		outList.append('END;')
		# for line in outList:
			# print(line)

		F = open(outFilePathName, 'w')
		for row in outList:
			F.writelines(row+'\n')
		F.close()
		
		outFilePathName = outFilePathName[0:-4] + '.lst'
		F = open(outFilePathName, 'w')
		address = 0
		for row in sourceFile:
			hexAddr = hex(address)
			hexAddr = hexAddr[2:]
			if len(hexAddr) == 1:
				outStr = '00' + hexAddr + '\t'
			elif len(hexAddr) == 2:
				outStr = '0' + hexAddr + '\t'
			else:
				outStr = hexAddr + '\t'
			cellOff = 0
			ioRd = False
			ioWr = False
			for cell in row:
				if cell == '':
					outStr += '\t\t'
				else:
					if cellOff == 2:
						if cell == 'IOR':
							ioRd = True
						if cell == 'IOW':
							ioWr = True
					if cellOff == 3:
						if cell[0:2] == '0X':
							if cell[3:] == '8':
								outStr += '#0x00' + '\t'
							elif cell[3:] == '9':
								outStr += '#0x01' + '\t'
							elif cell[3:] == '9':
								outStr += '#0xFF' + '\t'
							else:
								outStr += 'Reg' + cell[3:] + '\t'
						else:
							outStr += cell + '\t'
					elif cellOff == 4:
						if not (ioRd or ioWr):
							outStr += cell + '\t'
						else:
							# if cell == '0X04':
								# outStr += 'I2C_DAT' + '\t'
							# elif (cell == '0X05') and ioRd:
								# outStr += 'I2C_STA' + '\t'
							# elif (cell == '0X05') and ioWr:
								# outStr += 'I2C_CTL' + '\t'
							# elif (cell == '0X00') and ioWr:
								# outStr += 'LEDS0' + '\t'
							# elif (cell == '0X01') and ioWr:
								# outStr += 'LEDS1' + '\t'
							# elif (cell == '0X02') and ioWr:
								# outStr += 'LEDS2' + '\t'
							# elif (cell == '0X02') and ioWr:
								# outStr += 'LEDS3' + '\t'
							# else:
								# outStr += 'TBDIO' + '\t'
							if memMapList != []:
								portStr = self.getMemMapStr(cell,ioRd,ioWr,memMapList)
								if portStr == '':
									outStr += 'IO_' + cell[2:] + '\t'
								else:
									outStr += portStr + '\t'
							else:
								outStr += 'IO_' + cell[2:] + '\t'
					else:
						outStr += cell + '\t'
				cellOff += 1
			outStr += '\n'
			F.writelines(outStr)
			address += 1
		F.close()
		
	def getMemMapStr(self,regNum,ioRd,ioWr,memMapList):
		"""
		"""
		for row in memMapList[1:]:
			if regNum[2:] == row[0][2:]:
				if (row[1] == 'R' or row[1] == 'RW') and ioRd:
					return(row[2])
				elif (row[1] == 'W' or row[1] == 'RW') and ioWr:
					return(row[2])
		return ''
	
			
class Dashboard:
	def __init__(self):
		self.win = Tk()
		self.win.geometry("320x240")
		self.win.title("pyAssemble-cpu001")

	def add_menu(self):
		self.mainmenu = Menu(self.win)
		self.win.config(menu=self.mainmenu)

		self.filemenu = Menu(self.mainmenu, tearoff=0)
		self.mainmenu.add_cascade(label="File",menu=self.filemenu)

		self.filemenu.add_command(label="Open asm file",command=control.doConvert)
		self.filemenu.add_separator()
		self.filemenu.add_command(label="Exit",command=self.win.quit)

		self.win.mainloop()
		
if __name__ == "__main__":
	if version_info.major != 3:
		errorDialog("Requires Python 3")
	control = ControlClass()
	x = Dashboard()
	x.add_menu()
