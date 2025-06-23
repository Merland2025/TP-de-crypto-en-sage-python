R.<x> = PolynomialRing(GF(2))
F.<a> = GF(2^8, modulus = x^8 + x^4 +x^3 +x +1)
alpha = F.gen()

def p2h(p):
    if p.degree() > 7:
        print('pnôme de degrée trop grand')
        return

    binary = p.list()
    n = 0

    for i in range(len(binary)):
        n = n + int(binary[i]) * 2^i

    return hex(n)

def h2p(h, R):
    n = int(h,16)
    binary = list(bin(n)[2:])

    binary.reverse()
    p = R(binary)

    if p.degree() > 7:
        print('pnôme de degrée trop grand')
        return

    return p

def sumh(h_1 , h_2, R):
    a = h2p(h_1, R)
    b = h2p(h_2, R)

    c = a + b
    s = p2h(c)

    return s

def multbyX(h, R):
    p = h2p(h, R)
    mask = '0x1b'
    p_shift = [0] + p.list()[:7]
    p_X = R(p_shift)
    p_X_h = p2h(p_X)

    if p.degree() == 7:
        p_X_h = sumh(mask, p_X_h, R)
       
    return p_X_h

def multh(h_1, h_2, R):
    a = h2p(h_1, R)
    b = h2p(h_2, R)
    c = '0x00'

    p = p2h(a)
    for i in range (b.degree() + 1):
        if b.list()[i] == 1:
            c = sumh(c, p, R)

        p = multbyX(p, R)

    return c

def exp2pol(prim, R):
    l = ['0x1']
    p = '0x1'
    for i in range(254):
        p = multh(p, prim, R)
        l.append(p)

    return l

def pol2exp(prim, R):
    l_0 = exp2pol(prim, R)
    
    l = [l_0.index(hex(i)) for i in range(1, 256)]
    l = ['?'] + l

    return l

def inv_h(h,a,R,F):
    if h == hex(0):
        return h
    p = h2p(h,R)
    eval_p = p(a)
    inv_eval_p = eval_p ^-1
    inv_p = R(inv_eval_p.polynomial().list())
    inv_hex = p2h(inv_p)

    return inv_hex

def multh_faster(h_1, h_2, T_exp, T_pol):
    pw_1 = T_exp[int(h_1, 16)]
    pw_2 = T_exp[int(h_2, 16)]

    pw = (pw_1 + pw_2) % 255

    return T_pol[pw]

def SubBytes(h,a,R,F):
    first_row = vector(GF(2),[1,0,0,0,1,1,1,1])
    M = matrix.circulant(first_row)
    c = vector(GF(2),[1,1,0,0,0,1,1,0])
    a_1 = vector(GF(2),[0,0,0,0,0,0,0,0])

    h_iv = inv_h(h,a,R,F)
    n = int(h_iv,16)
    binary = list(bin(n)[2:])
    binary.reverse()
    for i in range(len(binary)):
        if binary[i] == '1':
            a_1[i] = 1

    b = M * a_1.column() + c.column()

    b_l = b.list()
    n = 0
    for i in range(8):
        if b_l[i] == 1:
            n = n + 2^i

    return hex(n)

def InvSubBytes(h,a,R,F):

    first_row = vector(GF(2),[1,0,0,0,1,1,1,1])
    M = matrix.circulant(first_row)
    c = vector(GF(2),[1,1,0,0,0,1,1,0])
    b = vector(GF(2),[0,0,0,0,0,0,0,0])

    n = int(h,16)
    binary = list(bin(n)[2:])
    binary.reverse()
    for i in range(len(binary)):
        if binary[i] == '1':
            b[i] = 1

    a_1 = M^-1 * (b.column() + c.column())

    a_1l = a_1.list()
    n = 0
    for i in range(8):
        if a_1l[i] == 1:
            n = n + 2^i
    
    h_iv = inv_h(hex(n),a,R,F)

    return h_iv

def S_box(a,R,F):
    S = [SubBytes(hex(i),a,R,F) for i in range(256)]
    iS = [InvSubBytes(hex(i),a,R,F) for i in range(256)]

    return S, iS

def MixColumns(C, T_exp, T_pol, R):
    A = matrix.circulant([2,3,1,1])
    M = []
    for i in range(4):
        s = '0x0'
        for j in range(4):
            m = multh_faster(hex(A[i,j]), C[j], T_exp, T_pol)
            s = sumh(s, m, R)
        M.append(s)
    
    return M

def InvMixColumns(C, T_exp, T_pol, R):
    B = matrix.circulant([14,11,13,9])
    M = []
    for i in range(4):
        s = '0x0'
        for j in range(4):
            m = multh_faster(hex(B[i,j]), C[j], T_exp, T_pol)
            s = sumh(s, m, R)
        M.append(s)
    
    return M

###############################Questions du TP#################################
print('############################### Questions du TP #################################')
print('\n1-a)')
print('on définit l’anneau des polynomes sur F_2 avec la commande:')
print('R.<x> = PolynomialRing(GF(2))')

print('\n1-b/c)')
print('La fonction permettant de convertir la représentation polynomiale en la repré-\nsentation hexadécimale est:')
print('p2h(p)')
print('où')
print('- p un polynome')
print('')
print('La fonction permettant de convertir la représentation hexadécimale en la repré-\nsentation polynomiale est:')
print('h2p(h, R)')
print('où')
print('- h est un hexadécimal de type string (ex: \' 0x3 \')')
print('- R l’anneau des polynomes')

print('\n1-d)')
print('La fonction permettant de faire une somme est:')
print('sumh(h_1 , h_2, R)')
print('où')
print('- h_1, h_2 hexadécimaux (de type string)')
print('- R l’anneau des polynomes')
print('')
print('sumh(\'0x57\', \'0x83\', R)')
s_1 = sumh('0x57', '0x83', R)
print(s_1)


print('\n1-e)')
print('La fonction permettant de faire une multiplication est:')
print('multh(h_1, h_2, R)')
print('où')
print('- h_1, h_2 hexadécimaux (de type string)')
print('- R l’anneau des polynomes')

print('\n1-f)')
print('multh(\'0x57\', \'0x83\', R)')
m_1 = multh('0x57', '0x83', R)
print(m_1)

print('\n1-g)')
print('On définit F_2^8 avec:')
print('F.<a> = GF(2^8, modulus = x^8 + x^4 +x^3 +x +1)')
print('Pour vérifier le résultat précédent on fait les instructions suivantes:')
print('p_0x57 = a^6 + a^4 + a^2 + a + 1')
p_0x57 = a^6 + a^4 + a^2 + a + 1
print('p_0x83 = a^7 + a + 1 ')
p_0x83 = a^7 + a + 1 
print('r = p_0x57 * p_0x83')
r = p_0x57 * p_0x83
print('m_2 = p2h(R(r.polynomial().list()))')
m_2 = p2h(R(r.polynomial().list()))
print('a-t-on le même résultat?')
print(m_1 == m_2)

print('\n1-h)')
print('ordre = (a + 1).multiplicative_order()')
ordre = (a + 1).multiplicative_order()
print('l’ordre de a + 1 est de',ordre,' donc c’est un générateur de (F_2^8, *)× ainsi \n(x + 1) est primitif')

print('\n1-i)')
print('L’instruction qui donne (en hexadécimal) la puissance k de X + 1 telle que\nP = (X + 1)^k est:')
print('pol2exp(\'0x3\',R)[P]')
print('où')
print('- R l’anneau des polynomes')
print('- P un polynome en hexadécimal (de type string)')

print('\n1-j)')
print('L’instruction qui donne (en hexadécimal) le polynome (X + 1)^k sous forme deve-\nloppée est:')
print('exp2pol(\'0x3\', R)[k]')
print('où')
print('- R l’anneau des polynomes')
print('- une puissance en hexadécimal (de type string)')

print('\n1-k)')
print('La fonction permettant de faire une multiplication plus rapidement est:')
print('multh_faster(h_1, h_2, T_exp, T_pol)')
print('où')
print('- h_1, h_2 hexadecimaux (de type string)')
print('- T_exp le tableau obtenu par pol2exp(\'0x3\',R)')
print('- T_pol le tableau obtenu par exp2pol(\'0x3\',R)')

T_exp = pol2exp('0x3',R)
T_pol = exp2pol('0x3', R)
m_3 = multh_faster('0x57', '0x83',T_exp, T_pol)
print('multh_faster(\'0x57\', \'0x83\',T_exp, T_pol)')
print(m_3)

print('\n2-a)')
s_b = SubBytes('0x11',a,R,F)
print('SubBytes(\'0x11\',a,R,F) donne',s_b)

print('\n2-b)')
print('On converti l’hexadécimal donné en vecteur, on retranche (1,1,0,0,0,1,1,0) puis\non multiplie par l’inverse de la matrice. Il faut faire toutes ces operations \ndans GF(2).')

is_b = InvSubBytes(s_b,a,R,F)
print('InvSubBytes(s_b,a,R,F)')
print('on retrouve bien',is_b)

print('\n2-c)')
print('La fonction S_box(a,R,F) rend les deux tableaux S et iS')

print('\n3-a)')
print('On definit F_2^8[y] avec:')
print('S.<y> = PolynomialRing(F)')
S.<y> = PolynomialRing(F)

print('Pour vérifier que c(y) est inversible on fait les instructions suivantes:')

print('c = 0x03*y^3 + y^2 + y + 0x02')
c = 0x03*y^3 + y^2 + y + 0x02

print('d = 0x0b*y^3 + 0x0d*y^2 + 0x09*y + 0x0e')
d = 0x0b*y^3 + 0x0d*y^2 + 0x09*y + 0x0e

print('c*d % (y + 1) =', c*d % (y + 1))
print('ainsi c(y) est inversible et d’inverse d(y)')

print('\n3-b)')
print('matrix.circulant([14,11,13,9])')
B = matrix.circulant([14,11,13,9])
print(B)
print('')
print('MixColumns(C, T_exp, T_pol, R)')
print('où')
print('- C le vecteur (d’hexadecimaux de type string) de la colonne à melanger')
print('- R l’anneau des polynomes')
print('- T_exp le tableau obtenu par pol2exp(\'0x3\',R)')
print('- T_pol le tableau obtenu par exp2pol(\'0x3\',R)')
print('')
print('InvMixColumns(C, T_exp, T_pol, R)')
print('où')
print('- C le vecteur (d’hexadecimaux de type string) de la colonne à melanger')
print('- R l’anneau des polynomes')
print('- T_exp le tableau obtenu par pol2exp(\'0x3\',R)')
print('- T_pol le tableau obtenu par exp2pol(\'0x3\',R)')

