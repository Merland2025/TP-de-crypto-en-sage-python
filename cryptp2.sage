def new_ascii_tab():
    L = []
    for i in range(32,123):
        L.append(chr(i))

    L.append(chr(10))

    return L

def txt2ascii(txt):
    L = new_ascii_tab()
    l = len(txt)
    trad = []
    
    for j in range(l):
        trad.append(L.index(txt[j]))

    return trad

def vigenere_tab():
    n = 92
    V = Matrix([[(i+j )% n for i in range(n)] for j in range (n)])

    return V

def vigenere(txt,key):
    V = vigenere_tab() 
    A = new_ascii_tab()
    P = txt2ascii(txt)
    K = txt2ascii(key)
    C = []
    size_txt = len(txt)
    size_key = len(key)

    for i in range(size_txt):
        row = K[i % size_key] 
        col = P[i]
        C.append(A[V[row,col]])

    return C

def dechiffrement_vigenere(txt,key):
    V = vigenere_tab() 
    A = new_ascii_tab()
    C = txt2ascii(txt)
    K = txt2ascii(key)
    P = []
    size_txt = len(txt)
    size_key = len(key)

    for i in range(size_txt):
        row = K[i % size_key] 
        in_row = C[i]
        clear = V[row].list().index(in_row)
        P.append(A[clear])

    return P

def tab_distance(txt,frame_size):
    tab_dist = []
    txt_size = len(txt) + 1
    d = dict((i,txt[i:i + frame_size]) for i in range(txt_size - frame_size))
    dd = sorted(d.items(), key=lambda item: item[1])
    dico_size = len(dd)
    ref = dd[0]
    for i in range(1, dico_size):
        if dd[i][1] != ref[1]:
            ref = dd[i]
            
        dist = dd[i][0] - ref[0]
        if dist != 0:
            tab_dist.append(dist)
    return tab_dist

def kasiski(txt,frame_size):
    #tableau des distance
    td = tab_distance(txt,frame_size)
    #set des distance
    sd = sorted(list(set(td)))
    #tableau distance/occurence
    tdo = [[sd[i],td.count(sd[i])] for i in range(len(sd))]
    #tableau distance/occurence trié par les occurance
    tdot = sorted(tdo, key = lambda item:item[1] ,reverse=True)
    #on garde que les 5 (choix arbitraire) ditances les plus fréquentes
    v = [tdot[i][0] for i in range(5)]
    n = gcd(v)

    return n

def occurence_IC(txt):
    n = len(txt)
    trad = txt2ascii(txt)
    A = new_ascii_tab()
    tab = []
    IC = 0
    for i in range(92):
        char = A[i]
        n_letter = trad.count(i)
        tab.append([char,n_letter]) 
        IC = IC + (n_letter * (n_letter - 1))
    IC = IC / (n * (n - 1))

    return tab, IC

def friedman(txt):
    I = 0.0778
    N = 92
    n = len(txt)
    i = occurence_IC(txt)[1]
    key_size = ((I - 1/N) * n)/((n - 1) * i - n/N + I)
    return key_size

def txt_splicer(txt, d):
    l = len(txt)
    nb_sub_txt = d
    if d >= l:
        print('pas de sous texte d au moins 2 lettres')
        return

    if d > l/2:
        nb_sub_txt = l - d

    sub_txt = [txt[i::d] for i in range(nb_sub_txt)]

    return sub_txt

def sub_txt_IC_screening(txt,depth):
    IC_tab = []
    tolerance = 10/100
    for i in range(1,depth + 1):
        sub_txt = txt_splicer(txt, i)
        l = len(sub_txt)
        IC_tab.append(mean([occurence_IC(sub_txt[j])[1] for j in range(l)]))
    
    cutoff = max(IC_tab)*(1 - tolerance)
    for i in range(depth):
        if IC_tab[i] > cutoff:
            return i + 1

def analyse_freq(txt):
    L = new_ascii_tab()
    space_value = L.index(' ')
    freq_tab = occurence_IC(txt)[0]

    freq_tab_tri = sorted(freq_tab, key = lambda item:item[1], reverse = True)
    suspected_space_value = L.index(freq_tab_tri[0][0])
    key = suspected_space_value - space_value

    return L[key]

def get_key_vigenere(txt,key_size):
    sub_txt = txt_splicer(txt, key_size)
    nb_sub_txt = len(sub_txt)
    key = [analyse_freq(sub_txt[i]) for i in range(nb_sub_txt)]

    return key

def pretty_print(txt):
    print(''.join(txt))

################################################################################
load("alice.sage")

print('')
print("Question 1:")
print('')
print("La fonction permettant de passer d\'un texte à son codage ascii est:")
print("txt2ascii(txt)")
print('')

print('')
print("Question 2:")
print('')
print("texte2 = txt2ascii(texte)")

texte2 = txt2ascii(texte)

print("Pour afficher d\'une manière plus esthétique on peut utiliser la fonction:")
print("pretty_print(texte2)")
#pretty_print(texte2)
print('')

print('')
print("Question 3:")
print('')
print("La fonction de chiffrement de vigenère est:")
print("vigenere(txt,key)")
print("où:")
print("-txt est le texte brute à chiffrer")
print("-key la clé de chiffrement (de type string)")
print('')


print('')
print("Question 4:")
print('')
print("La fonction de déchiffrement de vigenère est:")
print("dechiffrement_vigenere(txt,key)")
print("où:")
print("-txt est le texte chiffré")
print("-key la clé de chiffrement (de type string)")
print('')


print('')
print("Question 5:")
print('')
print("cipher_txt = vigenere(texte,'le lapin blanc')")

cipher_txt = vigenere(texte,'le lapin blanc')

print("Pour afficher d\'une manière plus esthétique on peut utiliser la fonction:")
print("pretty_print(cipher_txt)")
#pretty_print(cipher_txt)
print('')

print('')
print("Question 6:")
print('')
print("La fonction kasiski(txt,frame_size) permet d\'effectuer l\'attaque de kasiski.")
print("où:")
print("-txt est le texte à déchiffrer")
print("-frame_size est la taille des motifs répétés à repérer dans txt.")
print("key_size_multiple = kasiski(cipher_txt, 10)")

key_size_multiple = kasiski(cipher_txt, 10)

print("On obtient", key_size_multiple," qui est la taile de notre clé")
print('')


print('')
print("Question 7:")
print('')
print("La fonction occurence_IC(txt) retourne:")
print("-un tableau à 2 colonnes: la première contient les 92 charactères et\nla seconde leurs nombres d'occurences dans txt")
print("-L\'indice de coïncidence")
print('')

print('')
print("Question 8:")
print('')
print("IC_texte = occurence_IC(texte)[1]")

IC_texte = round(occurence_IC(texte)[1],3)

print("L\'indice de coïncidence vaut" , IC_texte ,"et non 0.0778 la valeur\nattendue pour la langue française.")
print('')


print('')
print("Question 9:")
print('')
print("key_size_1 = friedman(cipher_txt)")

key_size_1 = round(friedman(cipher_txt),3)

print("on obtient une taille de clé de",key_size_1," et non 14. Cette erreur est\nsurement du au fait que l\'indice de coïncidence du texte original est eloigné\nde celui théorique en français.")
print('')


print('')
print("Question 10:")
print('')
print("La fonction txt_splicer(txt, d) permet d\'extraire les sous textes composés\ndes lettres distantes de d dans txt. Elle rend un tableau contenant tous\nles sous textes")
print('')

print('')
print("Question 11:")
print('')
print("On va déterminer l\'indice de coïncidence(IC) des sous textes (du texte\nchiffré) composées des lettres distantes de 2, puis de 3 etc. Dans cette liste\nd\'IC on remarque que pour certaines distances l\'IC est plus grande \nque les autres. De plus cela se produit périodiquement. Cette période sera\nnotre taille de clé.")
print('')
print("La sub_txt_IC_screening(txt,depth) fait la procédure ci-dessus.")
print("où:")
print("-txt est le texte dont on va extraire les sous textes.")
print("-depth est la distance où l\'on arrête d\'extraire les sous textes.")
print('')

print("key_size_2 = sub_txt_IC_screening(cipher_txt, 40)")

key_size_2 = sub_txt_IC_screening(cipher_txt, 40)
print('')

print("on obtient ",key_size_2," la bonne taille de clé.")
print('')

print('')
print("Question 12:")
print("Une fois la taille de clé obtenue (i.e 14), on extrait les sous textes\n(du texte chiffré) composés des lettres distantes de la taille de la clé.\nOn effectue une analyse de fréquence sur chaque sous textes puis on associe\nle charactère correspondant au décalage obtenu.")
print('')
print("La fonction get_key_vigenere(txt, key_size) fait celà.")

print('')
print("key = get_key_vigenere(cipher_txt, 14)")
key = get_key_vigenere(cipher_txt, 14)

print("Pour afficher d\'une manière plus esthétique on peut utiliser la fonction:")
print("pretty_print(key)")
print('key:')
pretty_print(key)
print('')

print("On effectue le déchiffrement:")
print('')

print("plein_txt = dechiffrement_vigenere(cipher_txt, key)")

plein_txt = dechiffrement_vigenere(cipher_txt, key)

print("Pour afficher d\'une manière plus esthétique on peut utiliser la fonction:")
print("pretty_print(plein_txt)")
#pretty_print(plein_txt)
