# -*- coding: utf-8 -*-

class Foo():
    """ 和差積商を計算する"""

    def add(self, a, b):
        """
        a と b の和を返却する。

        :param a: ほげほげ
        :param b: もげもげ
        :return: 和
        :rtype: int
        """

        x = a+b
        return x

    def sub(self, a, b):
        """
        a と b の差を返却する。
        """

        return a - b

    def multi(self, a, b):
        """
        a と b の積を返却する。
        """

        return a * b


    def div(self, a, b):
        """
        a と b の商を返却する。
        """

        return float(a) / float(b)


