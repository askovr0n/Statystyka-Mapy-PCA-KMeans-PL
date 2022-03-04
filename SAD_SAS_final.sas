/****************************************************************************/
/* 																			*/
/* 			Statystyczna Analiza Danych z pakietem SAS		 				*/
/* 																			*/
/* 						WNE UW 2021/22										*/
/* 																			*/
/* 					dr hab. Piotr Wjcik									*/
/* 																			*/
/****************************************************************************/
/*				Z A D A N I A    Z A L I C Z E N I O W E 					*/
/****************************************************************************/

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/* PRZED przystpieniem do rozwizywania zada prosz zapozna si
	z obowizujcymi zasadami (plik "SAD_zasady202122.pdf"). */
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */

/* Rozwizania zada zaliczeniowych naley przesa mailem na adres 
   pwojcik@wne.uw.edu.pl najpniej do piatku 28.01.2021 r. do pnocy.

Za kady rozpoczty dzie spnienia bdzie naliczane 10 punktw ujemnych.

Maksymalnie za rozwizanie zada zaliczeniowych mona zdoby 64 punktw.
Za prace domowe maksymalnie mona uzyska 35 punktw.

Skala ocen bdzie uwzgldniaa wyniki caej grupy, ale aby uzyska 
zaliczenie zaj naley w sumie uzyska co najmniej 60 punktw.

POWODZENIA !!!	*/


/******************************************************************/

/* Zrodlo danych: Diagnoza spoeczna (http://www.diagnoza.com/)
Diagnoza spoeczna to cykliczne badanie przeprowadzane przez zesp
prof. Czapiskiego na duej prbie respondentw. 
	Wszystkie analizy beda wykonywane na wynikach badania
	przeprowadzonego w roku 2015.

Zbir zosta przygotowany tak, e obejmuje tylko WYBRANE zmienne
z badania w roku 2015 + kilka dodatkowych zmiennych oglnych
	
Plik z danymi:
---------------
dane_diagnoza2015.sas7bdat - dane do badania
dane_diagnoza2015_formaty.csv - plik z zapisanymi formatami dla zmiennych


Pliki dodatkowe:
---------------
- zmienne_diagnoza2015.pdf - zawiera informacje o zmiennych w zbiorze (nazwa, format, etykieta)
- kwestionariusze_2015.pdf - kwestionariusz z DS 2015 - wybrane zmienne dotycz
   czci indywidualnej badania, ktra zaczyna si od strony 20. kwestionariusza.

UWAGA! nazwy zmiennych z roku 2015 zaczynaj si literami hp i zawieraj numer pytania,
np. zmienne o przedrostku hp2_ zawieraj odpowiedzi na kolejne podpunkty z pytania 2 
(patrz s. 22 pliku z kwestionariuszem), a zmienna hp34 zawiera odpowied na pytanie 34
(patrz s. 24 pliku z kwestionariuszem), itd.


*/


/* ----------------------------------------------------------------- */
/* Zadanie 0 - rozgrzewka :) */
x 'cd ';

/* ----------------------------------------------------------------- */
/* a. zaimportuj plik dane_diagnoza2015_formaty.csv tworzc zbir SAS 
   o nazwie: diagnoza_formaty */
/* 1 punkt */

libname dane '';

proc import datafile = ''
 out = work.diagnoza_formaty
 dbms = CSV
 ;
run;

/* poniszy kod pozwoli wczyta wszystkie formaty zapisane w zbiorze
   diagnoza_formaty (ma on odpowiedni konstrukcj) do biblioteki WORK */

proc format lib = work CntlIn = diagnoza_formaty;
run;


/* tu jest take odpowiednie miejsce na wczytanie wszystkich
	makr, ktre bd uywane w kolejnych zadaniach */

%include "sgplotCCCk.sas";
%include "sgplotCCCh.sas";
%inc "kmeanssuph.sas";
%inc "sgplotsegk.sas";
%inc "sgplotsegh.sas";

/* ----------------------------------------------------------------- */
/* b. Stwrz kopi zbioru z danymi w bibliotece WORK. */
/* 1 punkt */

data dane_diagnoza2015;
	set dane.dane_diagnoza2015;
run;

/* ----------------------------------------------------------------- */
/* c. ze zbioru dane_diagnoza2015 prosze wybrac losowa probe (bez zwracania)
      o liczebnosci 10000 obserwacji i zapisac ja w zbiorze o nazwie proba.
	  Plik uzyskany w tym cwiczeniu bedzie Twoja ostateczna proba, 
	  na ktorej zostana wykonane WSZYSTKIE kolejne cwiczenia. */
/* 2 punkty */

proc surveyselect data=dane_diagnoza2015 out=proba method=SRS
  sampsize=10000 seed=411423;
 run;


/* Szybki check na danych */
proc print data = proba (obs = 10);
run;

proc contents data = proba;
run;

/* ----------------------------------------------------------------- */
/* zadanie 1 */
/*  Przetestuj hipoteze, ze dla czterech losowo wybranych wojewdztw 
    liczba osb zaliczanych do grona swoich przyjaci 
    przez niepalcych mczyzn jest w kadym z nich taka sama. 
    Uwzgldnij tylko osoby, ktre maj co najmniej jednego przyjaciela.
	Losowego wyboru take dokonaj za pomoc kodu 4GL. */
/* 5 punktow */

proc sql;
create table wojewodztwa as
	select distinct wojewodztwo
	from proba;
quit;

proc surveyselect data = wojewodztwa
	out = wojewodztwa_4
	n = 4
	seed = 411423;
run;

proc print data = wojewodztwa_4;
run;

/*Dolnoœl¹skie -2, Lubelskie -6, Œl¹skie - 24, Zachodnopomorskie - 32 */
/* Check na numerach */
proc sql;
create table xyz as
	select wojewodztwo, count(*)
	from proba 
	group by wojewodztwo
;quit;

proc sql;
create table zad1 as
select *
from proba
where wojewodztwo in (2, 6, 24, 32) 
;quit;

/* Sprawdzam normalnosc zmiennych */
proc univariate data=zad1;
var hp39;
histogram hp39 / normal;
run;

proc univariate data=zad1;
var hp43;
histogram hp43 / normal;
run;

/* dwa razy brak normalnosci wiec test nieparametryczny na mediane */

proc npar1way data=zad1;
var hp39;
class wojewodztwo;
where hp39 > 0 and hp43 = 2;
ods select KruskalWallisTest;
run;

/* p-value - 0.0012, zatem odrzucam H0, ¿e liczba osób zaliczanych do grona swoich przyjació³ 
    przez niepal¹cych mê¿czyzn jest w ka¿dym z 4 losowo wybranych województw taka sama */


/* ----------------------------------------------------------------- */
/* zadanie 2 */
/* Przedstaw na mapie Polski podzia wojewodztw (cylindryczne slupki + 4 kolory) 
	wg udziau kobiet, ktre nie uprawiaj aktywnie adnej formy sportu czy
    wicze fizycznych, a reagujc na kopoty lub trudne sytuacje w ich yciu:
    - zwracaj si o rad i pomoc do innych ludzi LUB
    - mobilizuj si i przystpuj do dziaania LUB
    - zajmuj si innymi rzeczami, ktre odwracaj uwag i poprawiaj nastrj

   Wartosci procentowe w legendzie mapy prosz zaokragli do 2 miejsc po przecinku. */
/* 6 punktow */

proc sql;
create table zad2a as
	select *,
	case
		when PLEC_ALL = 1 and HP106_01 = 1 and (HP47_1 = 1 or HP47_2 = 1 or HP47_3 = 1) then 1
			else 0
			end as kobiety_zad_2
	from proba;
quit;

proc sort data = zad2a;
by wojewodztwo;
run;

proc means data=zad2a noprint;
var kobiety_zad_2;
by WOJEWODZTWO;
output out=zad_2
mean=kobiety_zad_2;
run;

data zad_2_2;
	set zad_2;
	if wojewodztwo = . then delete;
	output;
run;

data udzial_kobiet_per_woj;
	set zad_2_2;
	kobiety_zad_2=round(kobiety_zad_2, 0.01);
run;

proc means data=udzial_kobiet_per_woj;
var kobiety_zad_2;
by wojewodztwo;
output out= udzial_kobiet_per_woj_2;
run;

/* Pobranie map */
proc import datafile='' out=powiaty dbms=csv replace;
run;

proc import datafile='' out=regid dbms=tab;
run;

proc sort data=regid;
by id;
run;

data mapa_powiatow;
merge MAPS.poland regid;
by id;
run;

data mapa_powiatow;
merge maps.poland regid;
by id;
run;

proc sort data=mapa_powiatow;
by wojid;
run;

proc gremove data=mapa_powiatow
out= mapa_wojewodztw;
by wojid;
id id;
run;

proc gremove data=mapa_powiatow out=mapa_wojewodztw;
	by wojid;
	id id;
run;

goptions reset=all border cback=white ctext=black ftext=swiss htitle=2 htext=1;
pattern1 value=solid c=blue;
pattern2 value=solid c=yellow;
pattern3 value=solid c=green;
pattern4 value=solid c=red;

proc sql;
create table udzial_kobiet_per_woj_3 as
select *
from udzial_kobiet_per_woj_2
where _STAT_ = 'MEAN';
quit;

data udzial_kobiet_per_woj_4;
set udzial_kobiet_per_woj_3;
	wojid = _n_;
run;

proc gmap map=mapa_wojewodztw data=udzial_kobiet_per_woj_4;
id wojid; 
block kobiety_zad_2 / levels=4
coutline=black shape=cylinder;
title1 'Mapa dla Polski'; 
title2 ' Udzia³ kobiet które nie uprawiaj¹ aktywnie ¿adnej formy sportu czy
    æwiczeñ fizycznych';
run; quit;



/* ----------------------------------------------------------------- */
/* Zadanie 3 */
/* a. Przeprowadz analize glownych skladowych dla:
	- zmiennych opisujcych rne przekonania i postawy (pytanie 57)
	ALBO
	- zmiennych opisujcych zadowolenie z roznych aspektow zycia (pytanie 63)

    Opisz kolejne kroki, uzasadnij wybor liczby skladowych, 
	zainterpretuj je i nadaj im czytelne nazwy, a nastepnie 
	zapisz nowe zmienne komponentowe w wynikowym zbiorze). */
/* 6 punktow */

proc means data = proba mean;
	var HP57_01-HP57_20;
run;

proc factor data = proba 
			method = principal 
			msa 
			scree; 
	var HP57_01 - HP57_20;
run;

/* Wstepne oszacowanie wskazuje na 7 czynników (wartoœci w³asne > 1) */

ods output OrthRotFactPat=proba_czynniki7;

proc factor data=proba n=7 method=principal 
	rotate=varimax reorder;
	var HP57_01 - HP57_20;
run;

/* usuwam ³adunki mniejsze ni¿ 0.5 co do wartoœci bezwzglêdnej jako nieistotne */

data proba_czynniki7;
set proba_czynniki7;

    /* tworzê tablicê ze zmiennymi */
	array zmienne(7) factor1-factor7;

	/* dziêki temu mo¿emy siê odwo³ywaæ do poszczególnych 
	   zmiennych w pêtli jako do kolejnych elementów tablicy,
	   co u³atwia wykonanie tej samej operacji na du¿ej 
	   grupie zmiennych */

	do i=1 to 7;
		if (abs(zmienne(i))<0.5) then zmienne(i)=.;
		zmienne(i)=round(zmienne(i), 0.001);
	end;

	drop i;
run;

/* zapisujê 7 czynników do zbioru */

proc factor data = proba
			method = principal 
			rotate = varimax 
			noprint
			nfactors = 7
			out = proba_factors;
	var HP57_01 - HP57_20;
run;

/* podstawowe statystyki opisowe czynników */

proc means data = proba_factors;
	var factor1-factor7;
run;

/* standaryzujê uzyskane czynniki do przedzia³u [0,1],
	bo ³atwiej je wtedy porównywaæ miêdzy sob¹ */

proc stdize data=proba_factors out=proba_factors 
            method=range;
	var factor1-factor7;
run;

/* nadajê nazwy poszczególnym czynnikom */

data proba_factors;
set proba_factors;
	label factor1='F1. Przywi¹zanie do wartoœci materialnych';
	label factor2='F2. Niedocenianie niektórych ludzi';
	label factor3='F3. Pozytywne nastawienie do ¿ycia';
	label factor4='F4. Konsumpcjonizm';
	label factor5='F5. Legalizacja zwi¹zków partnerskich';
	label factor6='F6. Przywrócenie kary œmierci';
	label factor7='F7. Patriotyzm';
run;


/*zapisuje zbior do dalszych analiz */
data dane.proba_factors;
set proba_factors;
run;

/* ----------------------------------------------------------------- */
/* b. Dla zmiennych komponentowych uzyskanych w podpunkcie a. wykonaj 
    analize skupien metoda k-srednich. Wybierz optymaln liczb grup.
    Sprawd czy rozwizanie metody k-rednich z losowym wyborem pocztkowych
    rodkw cizkoci mona poprawi uywajc metody k-rednich
    wspomaganej metod hierarchiczn. 
    Wybierz najlepsze Twoim zdaniem rozwizanie, zapisz je w zbiorze danych
    i zinterpretuj uzyskane grupy w odniesieniu do zmiennych uytych
    do grupowania. */
/* 6 punktow */

/***/
/* Tworze analize skupien metoda k-srednich - zaczne od 4 skupien */

proc fastclus data=dane.proba_factors maxclus=4 
			list;
	var factor1-factor7;
	id wojewodztwo;
run;

/* makro dla kmeans i sprawdzam jaka liczba skupien wydaje sie byc najoptymalniejsza - niech maxclus odpowiada liczbie wojewodztw */
%sgplotCCCk(data = dane.proba_factors, 
            maxclus = 16, 
            inputs = factor1-factor7);


/* Niestety ze wzglêdu na ujemne statystyki CCC nie widac do konca poprawnego rozwiazania, dodatkowo cie¿ko doszukac sie maksymalnej wartosci dla obu statystyk (wylaczajac 0 skupien)
/* Chcielibyœmy aby CCC oraz pseudo-F byly jak najwyzsze ( i dodatnie), natomiast w tym przypadku liczba podzialu bylaby rowna 0 */
/* Dlatego wiêc, wezmê 3 skupienia, poniewa¿ wydaje mi siê, i¿ w tym miejscu wystêpuje pewne za³amanie siê oby dwu wartoœci */
/* Uznaje, ze NA TEN MOMENT jest to optymalna liczba grup */


/* Niemniej pobawmy siê jeszcze chwile i wykluczmy ma³o ró¿nicuj¹ce segmenty, a nastêpnie ponownie sprawdzmy pseudo-F i CCC */

%sgplotsegk(data = dane.proba_factors, 
            nclus = 3, 
            inputs = factor1 factor2 factor3 factor4
                     factor5 factor6 factor7, 
	        out = dane.proba_factors_cechy);

/* Usune 2 factory, ze wzglêdu na najwy¿sze odchylenia - factor6 i factor7 */

%sgplotCCCk(data = dane.proba_factors, 
            maxclus = 16, 
	        inputs = factor1-factor5);

/* Puszczam dla zerkniecia na zroznicowania (nie uwzglednilem tego w raporcie) */
%sgplotsegk(data = dane.proba_factors, 
            nclus = 3, 
            inputs = factor1-factor5, 
	        out = dane.proba_factors_cleaned);

/* Uda³o siê uzyskaæ trochê wiêcej za³amañ, natomiast CCC nadal ma ujemne wartoœci, co wskazuje na zró¿nicowanie pomiêdzy segmentami */
/* Nie mniej jednak, dla 4 segmentów zauwa¿amy, i¿ zdecydowanie za³amanie. */
/* Uznajmy wiêc, i¿ jest to poprawny wynik */


/* Do tej pory,wszystko robiliœmy losowo - sprawdzmy wiêc, co sie stanie, gdy wspomo¿emy siê hierarchiczn¹ metod¹ */
/* Dzialam na bazowych clustrach tzn. nie uwzgledniam zmniejszonej liczby factorów */

%inc "kmeanssuph.sas";

%kmeanssuph(data = dane.proba_factors, 
            method = ward, 
            nclus = 3, 
		    inputs = factor1-factor5, 
            out = dane.proba_factors_hierar);

/* Wydaje siê, i¿ CCC lekko wzros³o z poziomu oko³o -26 do -45 oraz Pseudo-F wzros³o z oko³o 1500 (?) do 1827 */

/* Zapiszmy oba rozwiazania, ze wspomaganiem i bez*/


proc sort data=dane.proba_factors_cleaned;
by numer150730;
run;

proc sort data=dane.proba_factors_hierar;
by numer150730;
run;

proc sort data=dane.proba_factors;
by numer150730;
run;

data dane.proba_factors_cleaned;
set dane.proba_factors_cleaned;
	rename cluster=clusterk4;
	label cluster=;
	keep numer150730 cluster;
run;

data dane.proba_factors_hierar;
set dane.proba_factors_hierar;
	rename cluster=clusterk4w;
	label cluster=;
	keep numer150730 cluster;
run;


data dane.proba_factors;
merge dane.proba_factors dane.proba_factors_cleaned dane.proba_factors_hierar;
	by numer150730;
run;

/* ----------------------------------------------------------------- */
/* c. Dla najlepszego rozwizania analizy skupie z podpunktu b.
   dokonaj profilowania uzyskanych grup z wykorzystaniem zmiennych:
   - wiek/przedzia wiekowy
   - plec
   - klasa wielkoci miejscowoci zamieszkania
   - poziom wyksztacenia
   - osobisty dochod miesieczny (na reke) srednio z ostatnich 3 miesiecy
   - korzystania z komputera
   - korzystania z internetu
   - korzystania z usgug bankowych
   - liczba ksiek (jakichkolwiek) przeczytanych (wysuchanych) w cigu ostatnich 12 miesicy
   - oceny caego dotychczasowego ycia
    */
/* 5 punktow */

/* cos chyba z klasa_miejscowosci jest nie tak ???? */
proc sql;
create table temp_klasa as
	select klasa_miejscowosci, count(*)
	from dane.proba_factors
	group by klasa_miejscowosci
;quit;

/* check dla zarobkow */
/* w proc sql nie ma over partition by, wiêc */
proc sql;
create table temp_zarobki as
	select clusterk4w, hp65, count(*) as liczba
	from dane.proba_factors
	where hp65 is not missing and clusterk4w is not missing
	group by clusterk4w, hp65
;quit;

proc sql;
create table temp_zarobki_2 as
	select clusterk4w, hp65, liczba
	from temp_zarobki
	group by clusterk4w
;quit;

proc freq data=dane.proba_factors;
	tables (wiek6_2015 plec_all klasa_miejscowosci poziom_wykszta_cenia_2015 hp65 hp99 hp100 hp102 hp111_1 hp3)*clusterk4w / norow;
run;
/*
1: wiek/przedzia wiekowy: 45-59 lat
   - plec: kobieta
   - klasa wielkoci miejscowoci zamieszkania: miasto
   - poziom wyksztacenia: ZASADNICZE ZAWODOWE
   - osobisty dochod miesieczny (na reke) srednio z ostatnich 3 miesiecy:2000
   - korzystania z komputera: TAK
   - korzystania z internetu: TAK
   - korzystania z usgug bankowych: TAK
   - liczba ksiek (jakichkolwiek) przeczytanych (wysuchanych) w cigu ostatnich 12 miesicy: 0
   - oceny caego dotychczasowego ycia: UDANE

2: wiek/przedzia wiekowy: 45-59 lat
   - plec: kobieta
   - klasa wielkoci miejscowoci zamieszkania: miasto
   - poziom wyksztacenia: ZASADNICZE ZAWODOWE
   - osobisty dochod miesieczny (na reke) srednio z ostatnich 3 miesiecy: 2000
   - korzystania z komputera: TAK
   - korzystania z internetu:TAK
   - korzystania z usgug bankowych: TAK
   - liczba ksiek (jakichkolwiek) przeczytanych (wysuchanych) w cigu ostatnich 12 miesicy: 0
   - oceny caego dotychczasowego ycia: UDANE

3:  wiek/przedzia wiekowy: 65+ lat
   - plec: kobieta
   - klasa wielkoci miejscowoci zamieszkania: miasto
   - poziom wyksztacenia: ZASADNICZE ZAWODOWE
   - osobisty dochod miesieczny (na reke) srednio z ostatnich 3 miesiecy: 2000
   - korzystania z komputera: TAK
   - korzystania z internetu: TAK
   - korzystania z usgug bankowych: TAK
   - liczba ksiek (jakichkolwiek) przeczytanych (wysuchanych) w cigu ostatnich 12 miesicy: 0
   - oceny caego dotychczasowego ycia: UDANE





/* ----------------------------------------------------------------- */
/* Zadanie 4 */
/* a. Dokonaj hierarchicznej analizy skupien NA POZIOMIE WOJEWDZTW
	analizujac ich podobienstwo pod wzgledem:
	- pierwszego kwartyla wieku respondenta
	- przecitnego pragnienia do zycia (pytanie "Jak silne w tych dniach jest Pana pragnienie ycia?")
	- mediany dochodu miesicznego netto (na rk) spodziewanego za 2 lata
    - sredniego indeksu BMI (waga w kg / (wzrost w metrach)^2)
	- proporcji osb, ktre w minionym tygodniu oglday telewizj mniej ni przez 2 godziny dziennie
	- proporcji osb z wyksztaceniem co najmniej rednim
	- odstpu midzykwartylowego dla liczby osb zaliczanych do przyjaci

Wybierz metode pozwalajaca uzyskac skupienia o minimalnej wewnatrzgrupowej 
wariancji. Dendrogram wyswietl poziomo. */
/* 7 punktow */

/* usuwam wojewodztwo, ktore ma wartosci nullowe */
proc sql;
create table proba_no_null as
	select *
	from proba
	where WOJEWODZTWO is not missing
;quit;


proc sort data=proba_no_null;
by WOJEWODZTWO;
run;

/* pierwszy kwartyl wieku respondenta */

proc means data=proba_no_null q1;
var wiek2015;
by WOJEWODZTWO;
output out=proba_4a_1
q1 = wiek2015;
run;

/* przeciêtne pragnienie ¿ycia - HP40 */

proc means data=proba_no_null noprint;
var HP40;
by WOJEWODZTWO;
output out=proba_4a_2
mean=HP40;
run;

/* mediany dochodu miesicznego netto (na rk) spodziewanego za 2 lata - hp66 */

proc means data=proba_no_null noprint;
var HP66;
by WOJEWODZTWO;
output out=proba_4a_3
median=HP66;
run;

/*BMI */
data proba_bmi;
	set proba_no_null;
	bmi = HP53/((HP52/100)**2);
run;

proc means data=proba_bmi noprint;
var bmi;
by WOJEWODZTWO;
output out=proba_4a_4
mean=bmi;
run;

/* proporcji osb, ktre w minionym tygodniu oglday telewizj mniej ni przez 2 godziny dziennie - hp70 */

proc freq data = proba_no_null;
table HP70;
run;

data proba_tv;
set proba_no_null;
if HP70=2 or HP70 = 3  then tv=1;
else tv=0;
run;

proc freq data = proba_tv;
table tv;
run;

proc means data=proba_tv noprint;
var tv;
by WOJEWODZTWO;
output out=proba_4a_5
mean=tv;
run;

/* proporcja osob z wykszta³ceniem conajmniej œrednim */

proc freq data = proba_no_null;
table eduk4_2015;
run;

data proba_wyksztalcenie_1;
set proba_no_null;
if eduk4_2015=3 or eduk4_2015 = 4
	then wyksz=1;
else wyksz=0;
run;

proc freq data = proba_wyksztalcenie_1;
table wyksz;
run;

proc means data=proba_wyksztalcenie_1 noprint;
var wyksz;
by WOJEWODZTWO;
output out=proba_4a_6
mean=wyksz;
run;

/* odstpu midzykwartylowego dla liczby osb zaliczanych do przyjaci - hp39 */

proc means data=proba_no_null noprint;
var hp39;
by WOJEWODZTWO;
output out=proba_4a_7 
qrange = hp39;
run;

data proba_4a;
merge proba_4a_1 proba_4a_2 proba_4a_3 proba_4a_4 proba_4a_5 proba_4a_6 proba_4a_7;
by WOJEWODZTWO;
keep WOJEWODZTWO _freq_  wiek2015 HP40 HP66 BMI tv wyksz HP39; 
run;

data proba_4a (rename=(wiek2015=factor1 HP40=factor2 HP66=factor3 BMI=factor4 tv=factor5 wyksz=factor6 HP39=factor7));
set proba_4a;
run;

/* standaryzacja zmiennych faktorowych */

proc stdize data=proba_4a out=proba_4a_factors 
            method=range; 
	var factor1-factor7;
run;

data proba4_factors;
set proba_4a_factors;
	label factor1='F1. Pierwszy kwartyl wieku respondenta';
	label factor2='F2. Przeciêtne pragnienie do ¿ycia';
	label factor3='F3. Mediana dochodu miesiêcznego netto';
	label factor4='F4. Œredni indeks BMI';
	label factor5='F5. Proporcja osób, które w minionym tygodniu ogl¹da³y telewizjê mniej ni¿ przez 2 godziny dziennie';
	label factor6='F6. Proporcja osób z wyksztaceniem co najmniej œrednim';
	label factor7='F7. odstêp miêdzykwartylowy dla liczby osób zaliczanych do przyjació³';
run;

proc cluster data=proba4_factors outtree=proba4_treeF
     method=ward;
	 var factor1-factor7;
     id WOJEWODZTWO;
run;


/* narysuj dendrogram */

proc tree data=proba4_treeF horizontal;
run;


/* Wed³ug mnie powinno byæ 2-6 segmentow */

/* ----------------------------------------------------------------- */
/* b. Wybierz optymalne rozwizanie.
	Wyswietl srednie wartosci charakterystyk wykorzystanych do grupowania
	dla poszczegolnych skupien i zinterpretuj uzyskane grupy. */
/* 5 punktow */

/*statystyka na wykresie */
%inc "sgplotCCCh.sas";
%sgplotCCCh(tree=proba4_treeF, maxncl=16);

/* chce podzielic na 9 segmentów */
%inc "sgplotsegh.sas";
%sgplotsegh(tree=proba4_treeF, /* nazwa zbioru z dendrogramem */
            nseg=9, /* liczba grup, na które chcemy podzieliæ
			           obserwacje i porównaæ na wykresie */
           /* lista zmiennych, których œrednie wartoœci
			  w poszczególnych segmentach chcemy porównaæ.
			UWAGA! nalezy wypisac liste wszystkich
              zmiennych (bez skrotowej skladni) */
            inputs=factor1 factor2 factor3 factor4
                   factor5 factor6 factor7);

proc cluster data=proba4_factors outtree=proba4_treeF
     method=ward;
	 var factor1-factor7;
     id WOJEWODZTWO;
run;

proc tree data=proba4_treeF 
          n=9 
          out=proba_seg9; 
	copy WOJEWODZTWO; 
run;

data proba4_seg9;
set proba_seg9;
   rename cluster=clusterh9;
   keep WOJEWODZTWO cluster;
run;

proc sort data=proba4_seg9;
	by WOJEWODZTWO;
run;

data proba9_factors;
merge proba4_factors proba4_seg9;
	by WOJEWODZTWO;
run;

/* zapisujemy plik trwale */

data dane.proba9_factors;
set proba9_factors;
run;


/* ----------------------------------------------------------------- */
/* Zadanie 5 */
/* a. Zweryfikuj hipoteze, ze rozk³ad pragnienia ¿ycia (w tych dniach)
   dla osób, które nie by³y w minionym miesi¹cu:
   - w kinie, teatrze lub na koncercie, ani
   - na spotkaniu towarzyskim   
	nie zalezy od klasy wielkoœci miejscowoœci zamieszkania */
/* 2.5 punktu */

/* Sprawdzam normalnosc */

proc univariate data=proba;
var HP40;
histogram HP40 / normal;
run;

/* W obu przypadkach brak normalnoœci */

proc npar1way data=proba;
var hp40;
class klasa_miejscowosci;
where HP71_1 = 0 & HP71_3 = 0;
ods select KruskalWallisTest;
run;


/* ----------------------------------------------------------------- */
/* b. Zweryfikuj hipoteze, ze czêstoœæ udzia³u w nabo¿eñstwach 
      osób mieszkaj¹cych w najwiêkszych miastach nie zalezy od plci. */
/* 2.5 punktu  */

proc univariate data=proba;
var HP38;
histogram HP38 / normal;
run;

proc npar1way data=proba;
var hp38;
class PLEC_ALL;
where KLASA_MIEJSCOWOSCI = 1;
ods select KruskalWallisTest;
run;

/* H0 : czêstoœæ udzia³u w nabo¿eñstwach osób w najwiêkszych miastach jest taka sama niezale¿nie od p³ci (nie zale¿y od p³ci)
p-value = 0.001 < 0.05 -> odrzucam h0 */
	

/* ----------------------------------------------------------------- */
/* c. Zweryfikuj hipoteze, ze srednie zadowolenie z pracy 
   i ze swego wyksztalcenia dla osób, które przynajmniej 1 godzinê
   tygodniowo poœwiêcaj¹ na czytanie prasy, s¹ sobie rowne */
/* 2.5 punktu */

proc ttest data=proba h0=0;
	paired HP63_11*HP63_13;
	where HP110 >= 1;
run;

/* odrzucam hipoteze 0 */

/* ----------------------------------------------------------------- */
/* d. Osobno dla kobiet i dla mê¿czyzn zweryfikuj hipoteze, ze 
   taki sam procent osób uwa¿a, ¿e ogólnie rzecz bior¹c wiêkszoœci ludzi 
   mo¿na ufaæ oraz, ¿e  demokracja ma przewagê nad wszelkimi innymi formami 
   rz¹dów */
/* 2.5 punktu */

proc sql;
create table proba2 as
	select
		*
		,case when HP58 = 1 then 1 else 0 end as UFAC
		,case when HP64 = 1 THEN 1 ELSE 0 END AS DEMO
	from proba;
quit;
run;

data zad5d_M;
	set proba2;
	where PLEC_ALL = 1;
run;

proc freq data=zad5d_M;
	tables UFAC*DEMO /agree;
run;

/* p-value <.0001 -> odrzucam h0, ze taki sam procent mezczyzn uwa¿a, ¿e ogólnie rzecz bior¹c wiêkszoœci ludzi 
   mo¿na ufaæ oraz, ¿e  demokracja ma przewagê nad wszelkimi innymi formami rz¹dów */

data zad5d_K;
	set Proba2;
	where PLEC_ALL = 2;
run;

proc freq data=zad5d_K;
	tables UFAC*DEMO /agree;
run;

/* p-value <.0001 -> odrzucam h0, ze taki sam procent kobiet uwa¿a, ¿e ogólnie rzecz bior¹c wiêkszoœci ludzi 
   mo¿na ufaæ oraz, ¿e  demokracja ma przewagê nad wszelkimi innymi formami rz¹dów */


/* ----------------------------------------------------------------- */
/* e. Uzywajac stosownych testow statystycznych odpowiedz na pytanie, 
    czy zadowolenie ze sposobu spêdzania wolnego czasu zale¿y od
	statusu spo³eczno-zawodowego respondenta. */
/* 2.5 punktu */

proc univariate data =  proba;
var HP63_12;
histogram HP63_12/normal;
run;

/* h0 odrzucam, wiec kruskall */

proc npar1way data=proba;
var HP63_12;
class status9_2015;
ods select KruskalWallisTest;
run;

/* H0: Zadowolenie ze sposobu spêdzania wolnego czasu nie zale¿y od statusu spo³eczno-zawodowego respondenta
p-value <.0001 -> odrzucam H0 */

/* ----------------------------------------------------------------- */
/* f. Policz i podaj interpretacje miary/miar wspolzaleznosci oceny ca³ego swojego 
    dotychczasowego ¿ycia i miesiecznego dochodu (na reke). */
/* 3 punkty */

/* Sprawdzam normalnosc */

proc univariate data=proba;
var HP3;
histogram HP3/normal;
run;

proc univariate data=proba;
var HP3;
histogram HP3/normal;
run;

/* obie zmienne nie s¹ z rozk³adu normalnego tak wiêc korelacja Spearmana (albo Kendall Tau) */

proc corr data =  proba
spearman;
var HP3 HP65;
run;

/* Spearman wynosi -0.23952 */

/* ----------------------------------------------------------------- */
/* g. Narysuj i zinterpretuj wykres podstawowych parametrow rozk³adu 
	liczby godzin korzystania z Internetu w ostatnim tygodniu
	w zale¿noœci od grupy wiekowej.
	Ogranicz siê do osob, które nigdy nie p³aci³y za treœci dostêpne 
    w Internecie */
/* 4 punkty */

data zad5g;
	set proba;
	where HP134_25 = 0;
run;

proc univariate data=zad5g noprint;
	var HP133;
  	class wiek6_2015;
 	histogram / nrows=3 ncols=4 intertile=1 vscale=count 
                midpoints=10 to 82 by 2;
	inset median='Median of time:' (4.2) n='No:' / noframe position=ne;
run;


