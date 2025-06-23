#!/usr/bin/env python3
def ascii_tab():
    ascii_t = []
    for i in range(128):
        ascii_t.append(chr(i))
    return ascii_t

def cvrt_to_ascii_value(txt):
    l = len(txt)
    trad = []
    for i in range(l):
        trad.append(ord(txt[i]))
    return trad

def cesar(txt,key):
    l = len(txt)
    cipher_txt = []
    for i in range(l):
        cipher_txt.append(chr((ord(txt[i]) + key)%128))
    return cipher_txt

def cesar_to_plain(cipher_txt, key):
    l =  len(cipher_txt)
    plain_txt = []
    for i in range(l):
        plain_txt.append(chr((ord(cipher_txt[i]) - key)%128))
    return plain_txt

def analyse_freq(txt):
    freq_tab = []
    l = len(txt)
    trad = cvrt_to_ascii_value(txt)
    for i in range(128):
        freq = 0
        for j in range(l):
            if trad[j] == i :
                freq = freq + 1
        freq_tab.append([freq,i])
    freq_tab.sort(reverse=True)
# la partie suivante essaye de trouver, quel caractère du texte chiffré
# correspond à l'espace. On teste avec les caractères du plus au moins fréquents.
# A chaque tentative on demande si le texte déchiffré est lisible si oui on arrete
# sinon on prend le caractère suivant
    tentative = 0
    invalid_answer = False
    while True:
        if not invalid_answer:
            key = freq_tab[tentative][1]-32
            print(''.join(cesar_to_plain(txt,key)))
        answer = input('is it readable ? (answer by yes or no)\n')
        if answer == "yes" or answer =="y" or answer == "oui" or answer == "o":
            print("the key was :", key)
            return
        elif answer == "no" or answer =="n" or answer == "non":
            tentative = tentative  + 1
            invalid_answer = False
        else:
            invalid_answer = True 
