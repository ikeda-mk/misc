# -*- coding: utf-8 -*- 

import xlwt
import xlrd

class ExcelUtil():
    """
    Excelファイルの読み込み/書き込みを行うユーティリティ
    """

    def read(self, path, sheetname):
        """
        Excelファイルを読み込む。

        :param path: 読み込むExcelファイルのパス(ファイル名含む)
        :type path: str
        :param sheetname: 読み込むシート名
        :type sheetname: str
        :return: 読み込んだデータ(2次元配列)
        :rtype: list

        """

        book = xlrd.open_workbook(path)
        sheet = book.sheet_by_name(sheetname)

        rows = []
        for i in range(sheet.nrows):
            row = []
            for j in range(sheet.ncols):
                val = sheet.cell_value(i, j)
                row.append(val)
            rows.append(row)

        return rows        

    def write(self, path, sheetname, rows):
        """
        Excelファイルを出力する。

        :param path: 出力するファイルのパス(ファイル名含む)
        :type path: str
        :param sheetname: 出力するシート名
        :type sheetname: str
        :param rows: 出力するデータ(2次元配列)
        :type rows: list

        """

        book = xlwt.Workbook()
        sheet = book.add_sheet(sheetname)

        for i in range(len(rows)):
            for j in range(len(rows[i])):
                sheet.write(i, j, rows[i][j])
        book.save(path)

if __name__ == "__main__":

    import sys
    import os

    data = [ 
        [u'名前', u'誕生日', u'年齢', u'チーム'], 
        [u'高橋みなみ', u'1991/4/8', u'23歳', 'A'],
        [u'渡辺麻友', u'1994/3/26', u'20歳', 'B'],
        ]
    
    excel = ExcelUtil()
    fname = os.environ['HOME'] + '/tmp/akb.xls'
    excel.write(fname, 'sheet', data)

    rows = excel.read(fname, 'sheet')

    for row in rows:
        for val in row:
            print val,
        print 

