def chiffrement_RSA(pub_key, plain_txt):
    cipher_txt = power_mod(plain_txt, pub_key[0], pub_key[1])

    return cipher_txt

def dechiffrement_RSA(priv_key, cipher_txt):
    plain_txt = power_mod(cipher_txt, priv_key[2], (priv_key[0]*priv_key[1]))

    return plain_txt
    
def dechiffrement_RSA_CRT(priv_key, cipher_txt):
    d = [priv_key[2] % (priv_key[i] - 1) for i in range(2)]
    c_d = [power_mod(cipher_txt,d[i],priv_key[i]) for i in range(2)]

    plain_txt = CRT(c_d, priv_key[:2])

    return plain_txt

def key_generation_rsa(t):
    invalid_key = True
    size = ceil(t/2)
    while invalid_key:
        n = 0
        while n.nbits() != t:
            p = ZZ.random_element(2,2^(size))
            q = ZZ.random_element(2,2^(size))
            n = p * q

        p_prime = p.is_pseudoprime()
        q_prime = q.is_pseudoprime()

        if p_prime and q_prime:
            invalid_key = False

    phi = (p - 1)*(q - 1)
    d = 0
    while gcd(d,phi) != 1:
        d = ZZ.random_element(2,n)

    e = xgcd(d,phi)[1] % phi

    priv_key = [p, q, d]
    pub_key = [e, n]

    return priv_key, pub_key

def test_RSA(t):
    priv_key, pub_key = key_generation_rsa(t)

    plain_txt = ZZ.random_element(0,pub_key[1])
    
    time = cputime()
    cipher_txt = chiffrement_RSA(pub_key, plain_txt)
    temps_chiffrement = cputime(time)

    time = cputime()
    d_1 = dechiffrement_RSA(priv_key, cipher_txt)
    temps_naif = cputime(time)

    time = cputime()
    d_2 = dechiffrement_RSA_CRT(priv_key, cipher_txt)
    temps_CRT = cputime(time)

    print('temps de chiffrement',temps_chiffrement)
    print('les déchiffrement est-il un succés?','\nnaif:', d_1 == plain_txt,'\nCRT:', d_2 == plain_txt)
    if temps_naif < temps_CRT:
        print('déchiffrement naif plus rapide que par CRT:',temps_naif,'<',temps_CRT)
    else:
        print('déchiffrement CRT plus rapide que par naif:',temps_CRT,'<',temps_naif)

#exponentiation rapide

def square_and_multiply(g, e, n):
    h = 1
    e_b = ZZ(e).digits(2)
    i = len(e_b) - 1
    while i >= 0:
        h = h^2 % n
        if e_b[i] == 1:
            h = h * g % n
        i = i - 1

    return h

def precomputed_sliding_window(g, size,n):
    l = 2^size
    precomputed = [power_mod(g,i,n) for i in range(l)]

    return precomputed

def sliding_window(g, e, k, n, precomp):
    h = 1
    e_b = ZZ(e).digits(2)
    i = len(e_b) - 1
    while i >= 0:
        if e_b[i] == 0:
            h = h*h % n
            i = i - 1
        else:
            s = max(i - k + 1, 0)
            while e_b[s] == 0:
                s = s + 1
            for j in range(i - s + 1):
                h = h*h % n
            sub_bin = e_b[s:i + 1]
            ind = 0
            for i in range(len(sub_bin)):
                ind = ind + sub_bin[i] * 2^i
            h = h * precomp[ind] % n
            i = s - 1

    return h

def random_n_bits(n):
    wrong_size = True
    while wrong_size:
        t = ZZ.random_element(2,2^n)
        if t.nbits() == n:
            wrong_size = False

    return t

def taille_optimale_fenetre(t):
    nb_mesure = 30
    best_time = [0,666]
    tendance = []
    for k in range(2,t + 1):
        temps_moyen = 0
        for i in range(nb_mesure):
            g = random_n_bits(t)
            e = random_n_bits(t)
            n = random_n_bits(t)
            r = power_mod(g,e,n)
            precalc = precomputed_sliding_window(g,k,n)
            time = cputime()
            r_1 = sliding_window(g,e,k,n,precalc)
            temps = cputime(time)
            if r != r_1:
                print('erreur de calcul')
                return
            temps_moyen = temps_moyen + temps

        temps_moyen = temps_moyen / nb_mesure
        if temps_moyen < best_time[1]:
            best_time[0] = k
            best_time[1] = temps_moyen
            if len(tendance)!= 0:
                tendance = []
        else:
            tendance.append(temps_moyen)

        if len(tendance) > 3:
            return best_time[0]

def square_and_multiply_vs_sliding_window(t,k):
    nb_mesure = 100
    temps_moyen_sqm = 0
    temps_moyen_sw = 0
    for i in range(nb_mesure):
        g = random_n_bits(t)
        e = random_n_bits(t)
        n = random_n_bits(t)
        r = power_mod(g,e,n)

        precalc = precomputed_sliding_window(g,k,n)
        time = cputime()
        r_1 = sliding_window(g,e,k,n,precalc)
        temps_sw = cputime(time)

        time = cputime()
        r_2 = square_and_multiply(g,e,n)
        temps_sqm = cputime(time)

        if r != r_1:
            print('erreur de calcul silding window')
            return
        if r != r_2:
            print('erreur de calcul square and multiply')
            return
        temps_moyen_sw = temps_moyen_sw + temps_sw
        temps_moyen_sqm = temps_moyen_sqm + temps_sqm
    
    temps_moyen_sw = temps_moyen_sw / nb_mesure
    temps_moyen_sqm = temps_moyen_sqm / nb_mesure
    if temps_moyen_sw > temps_moyen_sqm:
        print('square-and-multiply est plus performant que sliding window',temps_moyen_sqm,'<',temps_moyen_sw)

    if temps_moyen_sw < temps_moyen_sqm:
        print('square-and-multiply est moins performant que sliding window',temps_moyen_sqm,'>',temps_moyen_sw)

#factorisation

def p_moins_un_friable(n):
    B = 5
    g = 1
    while g == 1:
        a = ZZ.random_element(2,B)
        list_factors = prime_range(B + 1)
        k = 1
        for i in list_factors:
            while i <= B:
                j = i
                i = i * i
            k = k * j

        b = power_mod(a,k,n) - 1
        g = gcd(b,n)
        if g == 1:
            B = B * 2 + 1
    p = g
    q = n/g

    return p,q

def diff_2_square(n):
    m = round(n^(1/2))
    i = 0
    reste_non_carre = True
    while reste_non_carre:
        m = m + i
        reste = power_mod(m,2,n)
        i = i + 1

        if reste.is_square():
            reste_non_carre = False
            continue

        if sgn(i) == 1:
            i = -i -1
        else:
            i = -i + 1


    p = m - reste^(1/2)
    q = m + reste^(1/2)

    return p,q

#attaque RSA
def attaque_cle_de_trois(cipher,cle_pub):
    plain_cube = CRT(cipher,cle_pub)
    plain = plain_cube^(1/3)

    return plain

def developpement_fraction_continue(a, n):
    a_i_liste = []
    for i in range(n):
        a_i = a.floor()
        a_i_liste.append(a_i)
        if a_i == a:
            break
        f_i = a - a_i
        a = f_i^(-1)

    return a_i_liste

def suite_numerateur_denominateur_convergent(a,n):
    a_liste = developpement_fraction_continue(a,n)
    l = len(a_liste) - 1

    p_0 = a_liste[0]
    q_0 = 1
    p_1 = a_liste[1]*a_liste[0] + 1
    q_1 = a_liste[1]

    p_liste = [p_0, p_1]
    q_liste = [q_0, q_1]

    for i in range(n-1):
        if i + 2 > l:
            break
        p = a_liste[i + 2] * p_liste[i + 1] + p_liste[i]
        q = a_liste[i + 2] * q_liste[i + 1] + q_liste[i]
        q_liste.append(q)
        p_liste.append(p)
    
    return p_liste, q_liste

def attaque_wiener(pub_key, depth):
    f = pub_key[0] / pub_key[1]
    p,q = suite_numerateur_denominateur_convergent(f,depth)
    true_depth = len(p)
    plain = ZZ.random_element(1,pub_key[1])
    cipher = chiffrement_RSA(pub_key, plain)
    for i in range(true_depth):
        g = gcd(p[i],q[i])
        if g == 1:
            priv_key = [pub_key[1],1,q[i]]
            m = dechiffrement_RSA(priv_key,cipher)
            if m == plain:
                return p[i],q[i]

    print('pas assez profond')
    return

def factorisation_n_wiener(pub_key,depth):
    k,d = attaque_wiener(pub_key,depth)
    phi =(pub_key[0]*d - 1)/k
    b = pub_key[1] - phi + 1
    p = (b - sqrt(b^2 - 4 * pub_key[1]))/2
    q = (b + sqrt(b^2 - 4 * pub_key[1]))/2

    return p,q

#logarithme discret
def ran_walk(g,h,w,a,b,p):
    r = w % 3
    q = p - 1
    if r == 0:
        w = w*g % p
        a = a + 1 % q

    if r == 1:
        w = w * h % p 
        b = b + 1 % q

    if r == 2:
        w = w * w % p
        a = a * 2 % q
        b = b * 2 % q
    
    return w,a,b

import bisect

def pollard_rho(g,h,p):
    q = p - 1
    bad_initialisation = True
    while bad_initialisation:
        bad_initialisation = False
        a = ZZ.random_element(1,p)
        b = 0
        w = power_mod(g,a,p)
        walk = [w]
        pow_g = [a]
        pow_h = [b]

        no_collision = True
        miss = 0
        while no_collision:
            w,a,b = ran_walk(g,h,w,a,b,p)
            i = bisect.bisect_left(walk, w)
            walk.insert(i,w)
            if i != (len(walk) - 1):
                if walk[i] == walk[i + 1]:
                    no_collision = False

            if no_collision:
                miss = miss + 1

            pow_g.insert(i,a)
            pow_h.insert(i,b)
            if no_collision == False:
                u = gcd(pow_h[i] - pow_h[i + 1],q)
                if (pow_g[i + 1] - pow_g[i]) % u != 0 or u % q == 0:
                    bad_initialisation = True
   
    num = (pow_g[i + 1] - pow_g[i])/u
    den = (pow_h[i] - pow_h[i + 1])/u
    q = q/u

    n = num/den % q
    if u == 1:
        return n,miss

    solution_possible = [n + i*q for i in range(u)]
    for s in solution_possible:
        s = int(s)
        h_1 = power_mod(g,s,p)
        if h == h_1:
            return s,miss

def random_n_bits_prime(n):
    not_prime = True
    while not_prime:
        p = random_n_bits(n)
        if p.is_prime() and p > 3:
            not_prime = False

    return p

def pollard_rho_raisonnable(t):
    n = 2
    time_in_1 = True
    time_in_2 = True
    while time_in_1 or time_in_2:
        n = n + 1
        p = random_n_bits_prime(n)
        g = GF(p).multiplicative_generator()
        g = int(g)
        h = ZZ.random_element(1,p)
        if time_in_1:
            time_1 = cputime()
            _,_ = pollard_rho(g,h,p)
            temps_1 = cputime(time_1)
            if temps_1 > t:
                time_in_1 = False
                n_1 = n
                

        if time_in_2:
            time_2 = cputime()
            _,_ = pollard_rho_floyd(g,h,p)
            temps_2 = cputime(time_2)
            if temps_2 > t:
                time_in_2 = False
                n_2 = n

    return n_1,n_2

def pollard_rho_floyd(g,h,p):
    q = p - 1
    bad_initialisation = True
    while bad_initialisation:
        bad_initialisation = False
        a = ZZ.random_element(1,p)
        b = 0
        w = power_mod(g,a,p)

        a_z = a
        b_z = 0
        z = w
        no_collision = True
        miss = 0
        while no_collision:
            w, a, b = ran_walk(g,h,w,a,b,p)

            z, a_z, b_z = ran_walk(g,h,z,a_z,b_z,p)
            z, a_z, b_z = ran_walk(g,h,z,a_z,b_z,p)
            
            if z == w:
                no_collision = False
            else:
                miss = miss + 1
            
            if no_collision == False:
                u = gcd(b - b_z,q)
                if (a_z - a) % u != 0 or u % q == 0:
                    bad_initialisation = True 
   
    num = (a_z - a)/u
    den = (b - b_z)/u
    q = q/u

    n = num/den % q
    if u == 1:
        return n,miss

    solution_possible = [n + i*q for i in range(u)]
    for s in solution_possible:
        s = int(s)
        h_1 = power_mod(g,s,p)
        if h == h_1:
            return s,miss

def classique_vs_floyd(n):
    nb_mesure = 10
    t_moyen_rho = 0
    c_moyen_rho = 0

    t_moyen_floyd = 0
    c_moyen_floyd = 0
    for i in range(nb_mesure):
        p = random_n_bits_prime(n)
        g = GF(p).multiplicative_generator()
        g = int(g)
        h = ZZ.random_element(1,p)

        time = cputime()
        r_1,c_1 = pollard_rho(g,h,p)
        temps_rho = cputime(time)

        time = cputime()
        r_2,c_2 = pollard_rho_floyd(g,h,p)
        temps_floyd = cputime(time)

        t_moyen_rho = t_moyen_rho + temps_rho
        c_moyen_rho = c_moyen_rho + c_1

        t_moyen_floyd = t_moyen_floyd + temps_floyd
        c_moyen_floyd = c_moyen_floyd + c_2

    t_moyen_floyd = t_moyen_floyd / nb_mesure
    c_moyen_floyd = c_moyen_floyd / nb_mesure
    
    t_moyen_rho = t_moyen_rho / nb_mesure
    c_moyen_rho = c_moyen_rho / nb_mesure
    print('calcul du log discret d’un nombre à',n,'bits: pollard rho classique')
    print('le temps moyen est de',t_moyen_rho,'s')
    print('le nombre moyen d’étape avant collision est de:',c_moyen_rho.n())
    print('')
    print('calcul du log discret d’un nombre à',n,'bits: pollard rho floyd')
    print('le temps moyen est de',t_moyen_floyd,'s')
    print('le nombre moyen d’étape avant collision est de:',c_moyen_floyd.n())
    print('')
    print('conclusion:')
    if t_moyen_floyd > t_moyen_rho:
        print('la méthode pollard rho classique est la plus rapide')
    else:
        print('la méthode pollard rho floyd est la plus rapide')

    return

##############################################################################
#                           compte rendu du TP4                              #
##############################################################################

print('(1) RSA')
print('1-a) ')
print('la fonction permettant de chiffrer en RSA est:')
print('chiffrement_RSA(pub_key, plain_txt)')
print('où:')
print('-pub_key est un 2-uplet contenant dans l’ordre e et n ')
print('-plain_txt est un entier à chiffrer')
print('')
plain_txt = chiffrement_RSA([5,85],9)
print('chiffrement_RSA([5,85],9)')
print('résultat:',plain_txt)
print('')
print('1-b)')
print('la fonction permettant de déchiffrer en RSA est:')
print('dechiffrement_RSA(priv_key, cipher_txt)')
print('où:')
print('-priv_key est un 3-uplet contenant dans l’ordre p,q et d ')
print('-cipher_txt est un entier à déchiffrer')
print('')
cipher_txt = dechiffrement_RSA([5,17,13],59)
print('dechiffrement_RSA([5,17,13],59)')
print('résultat:',cipher_txt)
print('')
print('1-c)')
print('la fonction permettant de déchiffrer en RSA avec les restes chinois est:')
print('dechiffrement_RSA_CRT(priv_key, cipher_txt)')
print('où:')
print('-priv_key est un 3-uplet contenant dans l’ordre p,q et d ')
print('-cipher_txt est un entier à déchiffrer')
print('')
cipher_txt_2 = dechiffrement_RSA_CRT([5,17,13],59)
print('dechiffrement_RSA([5,17,13],59)')
print('résultat:',cipher_txt_2)
print('')
print('1-d)')
print('la fonction qui rend le 3-uplet priv_key et le 2-uplet pub_key est:')
print('key_generation_rsa(t)')
print('où:')
print('t est le nombre de bits voulu pour n')
print('')
print('1-e)')
priv_key,pub_key = key_generation_rsa(30)
print('RSA 30 bits')
print('cle public:\ne =',pub_key[0],'\nn =',pub_key[1])
print('cle privée:\np =',priv_key[0],'\nq =',priv_key[1],'\nd =',priv_key[2])
print('')
print('1-f)g)h)')
print('la fonction permettant d’afficher les résultats des tests demandés est:')
print('test_RSA(t)')
print('où:')
print('t est le nombre de bits voulu pour n')
print('')
test_RSA(1024)
print('')
print('(2) Exponentiation rapide')
print('2-a) ')
print('la fonction effectuant une exponentiation modulaire par la méthode\nsquare-and-multiply est:')
print('square_and_multiply(g,e,n)')
print('où:')
print('g est le nombre à élever')
print('e la puissance à laquelle on élève')
print('n le modulo')
print('')
print('2-b)')
print('la fonction effectuant une exponentiation modulaire par la méthode de la fenêtre\nglissante est:')
print('sliding_window(g, e, k, n, precomp):')
print('où:')
print('g est le nombre à élever')
print('e la puissance à laquelle on élève')
print('k la taille de la fenêtre')
print('n le modulo')
print('precomp une liste de puissance de g précalculée')
print('')
print('2-c)')
print('la fonction permettant de trouver la taille optimale pour la méthode de la \nfenêtre glissante est:')
print('taille_optimale_fenetre(t)')
print('où:')
print('t est le nombre de bits des paramètres g, e, n de la fonction sliding_window')
print('')
print('taille_optimale_fenetre(1024)')
print('(cette étape peut prendre un certain temps)')
opt = taille_optimale_fenetre(1024)
print('')
print('résultat:',opt)
print('')
print('2-d)')
print('la fonction permettant de comparer la performance de square and multiply et \nsliding window est:')
print('square_and_multiply_vs_sliding_window(t,k)')
print('où:')
print('t est le nombre de bits  des paramètres g, e, n des deux fonctions')
print('k est la taille de la fenetre pour la méthode de la fenetre glissante')
print('')
square_and_multiply_vs_sliding_window(1024,opt)
print('')
print('on remarque que les méthodes ont une performance quasi-équivalente')
print('')
print('(3)génération de nombres premiers avec le test de Rabin-Miller (facultatif)')
print('')
print('(4)')
print('la fonction permettant de factoriser un entier p avec p - 1 friable est:')
print('p_moins_un_friable(n)')
print('où:')
print('n est un entier')
print('')
n_a = 117827681420271584017432903522327303325344948050665323956545863
p_a,q_a = p_moins_un_friable(n_a)
print('la factorisation de:',n_a,'est \np =',p_a,'\nq =',q_a) 
print('')
print('(5) ')
print('la fonction permettant de factoriser un entier en utilisant la méthode de \nla différence entre 2 carrés est:')
print('diff_2_square(n)')
print('où:')
print('n est un entier')
print('')
n_b = 4433634977317959977189716351978918572296527677331175210881861
p_b,q_b = diff_2_square(n_b)
print('la factorisation de',n_b,'est \np =',p_b,'\nq =',q_b) 
print('')
print('(6) attaque RSA avec e = 3')
print('la fonction permettant une attaque sur e = 3  est:')
print('attaque_cle_de_trois(cipher,cle_pub)')
print('où:')
print('cipher est un 3-uplet contenant un même message envoyé à trois personnes \ndifférentes')
print('cle_pub est un 3-uplet contenant les modules public correspondant')
n1 = 2828397017089907131052840387106128713282514421195726109593859
n2 = 3093736383172883855913466918447482558463408826373170329533707
n3 = 4495119919511106064205284407123143309601197579854381074387973

c1 = 161340658484276930595607630148167439628632052300968205657282
c2 = 2920025432866783050696766042954529191133978814738805935291595
c3 = 742851878532958654303493521961761568283962501737283926134034
cle_pub_c = [n1,n2,n3]
cipher_c = [c1,c2,c3]
print('')
plain_c = attaque_cle_de_trois(cipher_c,cle_pub_c)
print('le message clair est:',plain_c)
print('')
print('(7) Attaque de wiener sur les exposant courts')
print('7-a)')
print('la fonction permettant de calculer le développement en fractions continues\nd’un nombre a jusqu’à l’indice n est:')
print('developpement_fraction_continue(a,n)')
print('')
print('7-b)(facultatif)')
print('')
print('7-c)')
print('la fonction permettant d’obtenir les suites des numérateurs et des \ndénominateurs jusqu’au n-ième convergent de a est:')
print('suite_numerateur_denominateur_convergent(a,n)')
print('')
print('7-d)')
print('la fonction permettant une attaque sur une clé privé d trops petite est:')
print('attaque_wiener(pub_key,depth)')
print('où:')
print('pub_key est un 2-uplet contenant dans l’ordre e et n')
print('depth la profondeur de recherche du convergent ayant les bonnes propriétés')
print('')
print('7-e)')
n_d = 2630048851947048265274043876774585976831617720728227254753421
e_d = 60177566799353897687038964037333604046539474788802464201235
pub_key_d = [e_d,n_d]
_,d_d = attaque_wiener(pub_key_d,100)
print('la clé privé d est:',d_d)
print('')
print('7-f)')
print('la fonction permettant de factoriser un entier n est:')
print('factorisation_n_wiener(pub_key,depth)')
print('où:')
print('pub_key est un 2-uplet contenant dans l’ordre e et n')
print('depth la profondeur de recherche du convergent ayant les bonnes propriétés')
print('')
p_e,q_e = factorisation_n_wiener(pub_key_d,100)
print('la factorisation de',n_d,'est \np =',p_e,'\nq =',q_e) 
print('')
print('(8)')
print('8-a)')
print('la fonction permettant de trouver le logarithme discret par la méthode de \npollard rho classique est:')
print('pollard_rho(g,h,p)')
print('où:')
print('g est la base du logarithme discret')
print('h est la valeur du logarithm discret')
print('p est un nombre premier qui est le modulo du logarithme discret')
print('')
print('8-c)')
print('la fonction permettant de trouver le logarithme discret par la méthode de \npollard rho floyd est:')
print('pollard_rho_floyd(g,h,p)')
print('où:')
print('g est la base du logarithme discret')
print('h est la valeur du logarithm discret')
print('p est un nombre premier qui est le modulo du logarithme discret')
print('')
print('8-b)')
print('la fonction permettant de trouver la taille du paramètre p de la fonction \npollard_rho et pollard_rho_floyd est:')
print('pollard_rho_raisonnable(t)')
print('où:')
print('t est le nombre de seconde qu’on juge raisonnable')
t_1,t_2 = pollard_rho_raisonnable(3)
print('')
print('p raisonnable est de',t_1,'pour le pollard rho classique')
print('p raisonnable est de',t_2,'pour le pollard rho floyd')
print('')
print('8-d)')
print('la fonction affichant le temps moyen et la nombre de collision moyennes pour \ndu calcul du log discret pour un entier à n bits est:')
print('classique_vs_floyd(n)')
print('')
print('(cette étape peut prendre un certain temps)')
print('')
classique_vs_floyd(30)


