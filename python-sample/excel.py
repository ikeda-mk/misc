# -*- coding: utf-8 -*-

import xlwt
import xlrd
import collections

def read(path, sheet_name):
    """
    Excelファイルを読み込む。

    :param path: 読み込むExcelファイルのパス(ファイル名含む)
    :type path: str
    :param sheet_name: 読み込むシート名
    :type sheet_name: str
    :return: 読み込んだデータ(2次元配列)
    :rtype: list

    """

    book = xlrd.open_workbook(path)
    sheet = book.sheet_by_name(sheet_name)

    rows = []
    for i in range(sheet.nrows):
        row = []
        for j in range(sheet.ncols):
            val = sheet.cell_value(i, j)
            row.append(val)
        rows.append(row)

    return rows


def write(path, sheet_name, rows):
    """
    Excelファイルを出力する。

    :param path: 出力するファイルのパス(ファイル名含む)
    :type path: str
    :param sheet_name: 出力するシート名
    :type sheet_name: str
    :param rows: 出力するデータ(2次元配列)
    :type rows: list

    """

    book = xlwt.Workbook()
    sheet = book.add_sheet(sheet_name)

    for i in range(len(rows)):
        for j in range(len(rows[i])):
            sheet.write(i, j, rows[i][j])
    book.save(path)


def list2dict(rows, header, value_start_index):
    ret = []

    for row in rows[value_start_index:]:
        dic=collections.OrderedDict()
        for i in range(len(row)):
            dic[header[i]] = row[i]
        print dic
        ret.append(dic)

    return ret


if __name__ == '__main__':

    import os

    home = os.environ['HOME']
    path = home + '/tmp/Book2.xlsx'

    rows = read(path, unicode('ほげほげ定義書', 'utf-8'))

    for row in rows:
        for v in row:
            print v,
        print

    import csv

    csv_writer = csv.writer(open('eggs.csv', 'wb'), delimiter=",", quotechar='|', quoting=csv.QUOTE_MINIMAL)
    for row in rows:
        print row
        csv_writer.writerow([unicode(v).encode("utf-8") for v in row])

    import json
    import codecs

    fp = open('sample.json', 'w')
    fp.close()
    #for row in rows:s
        # print json.dump({'a': 1, 'b': 2}, open('sample.json', 'w'))
        #json.dump([unicode(v).encode("utf-8") for v in row], open('sample.json', 'a'), indent=4, ensure_ascii=False)
    json.dump(rows[4:], codecs.open('sample.json', 'w', 'utf-8'), indent=4, ensure_ascii=False)

    header = ['num', 'db_name', 'schema_name', 'table_physical_name', 'table_logical_name',
              'column_physical_name', 'column_logical_name', 'comment']
    dicts = list2dict(rows, header, 4)



    json.dump(dicts, codecs.open('sample.json', 'a', 'utf-8'), indent=4, ensure_ascii=False)


