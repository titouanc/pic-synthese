# Informations générales

* Le dsPIC33f tourne à une fréquence de 40MHz (40 millions d'instructions par seconde), dénommée `FCy`

## Niveaux logiques

La marge de bruit d'une sortie X vers une entrée Y est donnée, pour LO : __VilY__ - __VolX__ , pour HI : __VihY__ - __VohX__ 

Abbréviations utilisée dans cette section:

* __Voh__: Voltage Output High
* __Vih__: Voltage Input High
* __Vth__: Voltage THreshold
* __Vil__: Voltage Input Low
* __Vol__: Voltage Output Low

### Norme TTL
* __Voh__: 2.4V
* __Vih__: 2.0V
* __Vth__: 1.5V
* __Vil__: 0.8V
* __Vol__: 0.4V

### Norme HCMOS
* __Voh__: 4.5V (4mA)
* __Vih__: 3.5V _(70%)_
* __Vth__: 2.5V
* __Vil__: 1.5V _(30%)_
* __Vol__: 0.3V (4mA)

### PIC18F (compatibilité TTL)
* __Voh__: 4.3V (3mA)
* __Vih__: 2.0V
* __Vth__: 1.5V
* __Vil__: 0.8V
* __Vol__: 0.6V (8mA)

### PIC18F (Schmidt Trigger)
* __Voh__: 4.3V (3mA)
* __Vih__: 4.0V _(80%)_
* __Vth__: 2.0V (flan descendant) / 3.0V (flanc montant)
* __Vil__: 1.0V _(20%)_
* __Vol__: 0.6V (8mA)

# Entrées / Sorties numériques

Plusieurs séries d'I/O (PORTA à PORTG), `x` ci-après. Certaines font
8 bits de large, d'autres 16.

**Attention, certaines pattes sont partagées avec l'ADC ou le PWM**

## Registres de direction des pattes I/O
* 1 = entrée, 0 = sortie
* `TRISx = 0x0001` pour configurer la patte 0 en entrée, tout le reste en sortie
* `TRISxbits.TRISx0 = 1` pour configurer l'entrée individuellement

## Registres de sortie des pattes I/O
* `LATx = 0x0001` pour écrire tous les bits en une fois
* `LATxbits.LATx0 = 1` pour écrire un bit individuellement

## Registres d'entrée des pattes I/O
* `int val = PORTx` pour lire toutes les entrées en une fois
* `int val = PORTx.Rx0` pour lire l'entrée individuellement 

# Timers

## Configuration

* Registres de période des timers: `PR1` à `PR9`, en nombre de cycles du processeur (même unité que `FCy`)
* `PRx = n`; va multiplier par n la durée d'une période du timer x et du coup, diviser par n le nombre de périodes par seconde. Pour faire simple, en prennant `p = n/FCy` (secondes) et `f = FCy/n` (Hz)  (!Attention! `n < 2^16` )
* Ne pas oublier que le timer se termine sur un comparateur d'égalité (quand le compteur est _**égal**_ à `PRx`). Pour générer une interruption tous les 4000 cycles, il faut donc configurer `PRx = 3999` (sinon, on compte 4001 cycles)

* Démarrer le timer: `T1CONbits.TON = 1` à `T9CONbits.TON = 1`
* Vérifier si la valeur du timer est atteinte: `IFS0bits.T1IF` à `IFS0bits.T9IF`
* __Il faut remettre ce bit à 0 manuellement !__

## Prescaling

Les registres de timer font 16 bits (max `65535/FCy = 1638` microsecondes). On peut utiliser
un prescaler (diviseur d'horloge), de facteur 8, 64 ou 256.

* `T1CONbits.TCKPS = 0b00` Pas de prescaling (1)
* `T1CONbits.TCKPS = 0b01` Prescaling de 8
* `T1CONbits.TCKPS = 0b10` Prescaling de 64
* `T1CONbits.TCKPS = 0b11` Prescaling de 256

De nouveau ici si on note m, la valeur de prescale alors la fréquence de référence est `F/m`, on a alors la période `p = m*n/F [s] et f = F/(n*m)` [Hz] .

## Mode 32 bits

Il est possible d'utiliser les timers 2 et 3 (16 bits) ou 4 et 5 en combinaison pour obtenir un timer 32 bits

* Mettre la paire 2/3 en mode 32 bits : `T2CONbits.T32 = 1`
* Mettre les 16 bits de poids faible dans PR2
* Mettre les 16 bits de poids fort dans PR3
* Configurer eventuellement le prescaling sur le timer 2
* Configurer eventuellement l'interruption sur le timer 3
* Lancer le timer 2 : `T2CONbits.TON = 1`

# ADC

Le PIC est équippé de 32 entrées analogiques, dont 3 utilisables sur la carte
d'extension (`AN0`, `AN1`, `AN3`). Les ADC convertissent une tension de max 3.3V sur 10 ou 12 bits.
La conversion n'est pas instantanée (plusieurs microsecondes).
Il y a deux étapes : l'échantillonage et la conversion. La fin de l'échantillonage et le début de la conversion peut être gérée par un timer ou manuellement. Le début de l'échantillonage peut être automatique ou manuel. La durée de la conversion est paramétrable par l'horloge interne du convertisseur.
Dans la suite, remplacer x par le numéro de l'ADC (1 ou 2)

## Configuration

* Mettre l'horloge pour contrôler le temps de conversion. La numérisation nécessite
12 périodes (12 T AD ) en mode 10 bits et 14 périodes (14 T AD ) en mode 12 bits.
Lorsqu’elle est basée sur l’horloge du cycle machine (F CY ), l’horloge de l’ADC est configurable à l’aide
des 8 bits ADCS de ADxCON3. La période T AD est alors donnée par : (AD1CON3bits.ADCS+1)/F_cy
Pour qu’une numérisation se déroule correctement, cette période doit être supérieure à 75ns.
* On peut mesurer la valeur sur 12 bits en mettant le bit `ADxCON1bits.AD12B` à 1
* Choisir l'entrée sur laquelle écouter : `ADxCHS0.CHS0A = y` où `y` est l'entrée
* Mettre l'entrée choisie en mode analogique : `ADxPCFGLbits.PCFGy = 0`
* `ADxCON1bits.ASAM = 1` : autoreset à 1 de `ADxCON1bits.SAMP` pour relancer l'échantillonage dès qu'une conversion est terminée. Sinon, il faudrait manuellement relancer l'échantillonage : `ADxCON1bits.SAMP = 1`.
* Activer l'ADC : `ADxCON1bits.ADON = 1`
* Si on veut déclencher une interruption à la fin de la conversion, on active le bit correspondant: `IEC0bits.ADxIE = 1`

## Conversion analogique

* Mettre fin à l'échantillonage et lancer la conversion: `ADxCON1bits.SAMP = 0` Cette mise à 0 est automatique si un timer est relié au convertisseur.
* Quand la conversion est terminée, le bit `ADxCON1bits.DONE` est mis à 1 et est automatiquement remis à 0 au lancement d'une conversion.
* On peut consulter le flag d'interruption (`IEC0bits.ADxIF`)
* Le résultat de la conversion est lisible dans le registre `ADCxBUF0` (16 bits).

## Relier l'ADC au Timer 3

Il est possible de configurer l'ADC1 pour lancer une conversion sur débordement
du timer 3 (idem pour l'ADC2 avec le timer 5), auquel cas il n'est pas nécessaire de tester et réinitialiser le bit 
`IFS0bits.TxIF` par contre il faut remettre le bit `IFS0bits.ADxIF` à 0.
La routine d'interruption est `_ADC1Interrupt`

* "Connecter" l'ADC 1 au timer 3: `AD1CON1bits.SSRC = 2`
* "Connecter" l'ADC 2 au timer 5: `AD2CON1bits.SSRC = 2`

# Interruptions

Il est possible d'appeler une fonction "callback" lors du déclenchement d'un
évènement comme le débordement d'un timer, la fin d'une conversion ADC ou la
réception d'un caractère sur le port série.

* Activer l'interruption pour un timer: `IEC0bits.TxIE = 1` (où `x` est le numéro du timer de 1 à 3)
* Activer l'interruption pour un ADC: `IEC0bits.ADyIE = 1` (où `y` est le numéro de l'ADC)

Il faut ensuite écrire la routine d'interruption correspondante:

    /* Routine d'interruption de débordement du Timer 1 */
    void _ISR _T1Interrupt (void){}

    /* Routine d'interruption de fin de conversion de l'ADC1 */
    void _ISR _ADC1Interrupt (void){}

Puis remettre le flag à 0
* `IFS0bits.TxIF = 0` pour un timer
* `IFS0bits.ADCyIF = 0` pour un ADC

# PWM

Le dsPIC33F possède 8 périphériques de comparaison de sortie (Output Compare),
connectés sur les ports `RD0` à `RD7`, renommés `OC1` à `OC8` si utilisés comme
tel. Le principe du PWM peut être vu comme un timer à deux registres de comparaison 
(un registre de période totale, un registre de période active).

Pour ce faire, on configure un timer usuellement, et on définit une période
active dans un deuxième registre, dans les mêmes unités que la période du timer.

Le rapport entre la période active et la période totale peut s'appliquer 
à la tension d'alimentation d'un moteur, par exemple.
Ex : `rapport = periode_active/periode` alors `tensionMoyenneMoteur = tensionAlimMoteur * rapport`

__Seul les timers 2 et 3 peuvent être utilisés pour le PWM__

## Configuration

* Définition de la période du timer: `PR2 = periode` ou `PR3 = periode`
* Définition de la période "active": `OCxRS = periode_active` (inférieur à PR2)
* Définition du timer source: `OCxCONbits.OCTSEL = 0` (__timer 2__ = 0, __timer 3__ = 1)
* Passage de la borne en mode PWM: `OCxCONbits.OCM = 0b110`
* Passage de la borne RDx correspondante en sortie :  `TRISDbits.TRISDx = 0`

__Ne pas oublier de lancer le timer__

Exemple:

    PR2 = 40000   // Timer 2 à 1kHz
    OC1CONbits.OCM = 0b110 // passage en mode PWM
    OC1RS = 10000 // Période active de 1/4 de la période du timer 
                  // (25% de puissance moyenne)
    OC1CONbits.OCTSEL = 0 //timer source : 2
    TRISDbits.TRISD0 = 0 // OC1->RD0, passage de la born RD0 en sortie
    T2CONbits.TON = 1 // lancement de la PWM
    

# Communication série (UART)

__UART: Universal Asynchronous Receiver Transmitter__. Le dsPIC33f en comporte 2
qui utilisent le protocole série standard RS-232.

Il faut configurer plusieurs paramètres:

* Le baud-rate (souvent 9600, 62500 ou 115200 bauds)
* La taille d'un symbole (nombre de bits, généralement 8)
* Le bit de parité: aucun, pair ou impair (contrôle d'erreur)
* Le stop bit: marque un stop après l'émission d'un symbole (généralement 1 bit)
car on ignore combien de temps peut se passer avant la prochaine émission d'un symbole et il faut s'assurer que la ligne soit en état LO pour recevoir le start bit suivant.

On désigne parfois le format en plus court. Exemple: 8N1 = symboles de 8 bits,
pas de bit de parité, 1 stop bit.

Certains paramètres doivent être fixés en fonction du périphériques de l'autre côté de la connexion.


## Configuration
Les UARTs 1 et 2 sont dénommés `x` ci après

* Ecrire le baud rate dans UxBRG, selon la formule `( FCy/(16*baudrate) ) - 1`
* Si besoin d'un plus grand baud rate, on peut mettre le bit UxMODEbits.BRGH à 1, la formule devient `( FCy/(4*bauds) ) - 1`
* Sélection du mode de parité et de la taille des symboles: `UxMODEbits.PDSEL = 0b00`
* Sélection du nombre de bits de stop: `UxMODEbits.STSEL = 0` (`0`=1 stop bit, `1`=2stop bits)
* Controle de flux : UxMODEbits.UEN = 0
* Sélection du mode de réception: `UxSTAbits.URXISEL = 0b00`
* Sélection du mode d'interruption pour l'envoi: `UxSTAbits.UTXISEL = 0b00`
* Activation de l'UART: `UxMODEbits.UARTEN = 1`
* Activation de l'émetteur: `UxSTAbits.UTXEN = 1` (uniquement si on souhaite émettre)
* Activation de l'interruption: `IEC0bits.U1RXIE` pour l'UART 1, `IEC1bits.U2RXIE` pour l'UART 2

### Modes de parité

Signification des valeurs pour le flag `UxMODEbits.PDSEL`

* `0b00` 8 bits de données, pas de bit de parité
* `0b01` 8 bits de données, parité paire
* `0b10` 8 bits de données, parité impaire
* `0b11` 9 bits de données, pas de bit de parité

### Modes de réception

Signification des valeurs pour le flag `UxSTAbits.URXISEL`

* `0b00` ou `0b01` Déclenchement de l'interruption après réception d'un symbole
* `0b10` Déclenchement de l'interruption quand le buffer est rempli aux 3/4
* `0b11` Déclenchement de l'interruption quand le buffer de réception est rempli

### Modes d'émission

Signification des valeurs pour le flag `UxSTAbits.UTXISEL`

* `0b00` Déclenchement de l'interruption quand une place vient d'être libérée dans le buffer (envoi en cours)
* `0b01` Déclenchement de l'interruption quand tous les envois sont terminés
* `0b10` Déclenchement de l'interruption quand le buffer vient d'être vidé (envoi du dernier message en cours)
* `0b11` Réservé


## Émission

* Avant d'émettre, il faut vérifier qu'il y a de la place dans le buffer d'émission 
(BufferFull) : `while (UxSTAbits.UTXBF == 1)`
* Placer le caractère dans le buffer (FIFO): `UxTXREG = caractère`
* Attendre que le caractère soit transmis: `while (UxSTAbits.TRMT == 0)` (facultatif)

## Réception

Si la réception est configurée sur interruption, il faut définir une Interrupt Service Routine

    void _ISR _UxRXInterrupt(void){
        /* Tant qu'il ya des données disponibles dans le buffer d'entrée... */
        while (UxSTAbits.URXDA){
            char received = UxRXREG;
        }
    }

Il ne faut pas shifter le buffer d'entrée manuellement (FIFO hardware). 
Attention, une donnée lue est supprimée du buffer, la lecture suivante passera au symbole suivant.

