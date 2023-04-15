#!/usr/bin/perl

use MIME::Base64;
use Unicode::String qw(latin1 utf8); 

############ main ########################

%umlautMap = loadUmlautMap();
%map = loadKeyMap();

$i = 0;
# load csv-Datei
while (<>) {
    chomp;
    push(@feld,$_);
}

$datei="./out.ldif";
open (OUT,">$datei") || die "Kann Datei nicht anlegen\n" ;

open (LOG,">>./csv2ldif.log") || die "Kann Datei nicht anlegen\n" ;
print LOG "start csv2ldif";

$x=@feld[0];
$x =~ s/\"//g;

@keys=split(/,/,$x);
for ($i = 1; $i < @keys; $i++) {
    print LOG "\n#########################################\n";
    $xx = @feld[$i]; 
    $xx =~ s/\"//g;
    print LOG "nach match: $xx \n";
    @zeile=split(/,/,$xx);
    print LOG "zeile: @zeile \n";
    $j = 0;
    foreach (@zeile) {
        if ($map{$keys[$j]}) {
            $newMapWithUmlaut{$map{$keys[$j]}} = $_;
            $newMap{$map{$keys[$j]}} = umlautTest($_);
#            $newMap{$map{$keys[$j]}} = umlautReplace($_);
            print LOG "newkey / value: $map{$keys[$j]} /  $newMap{$map{$keys[$j]}} \n";
        } else {
        }
        $j++;
    }
#    $vorname=umlautReplace($newMapWithUmlaut{"givenName"});
#    $vorname=umlautTest($newMapWithUmlaut{"givenName"});
    $vorname=$newMapWithUmlaut{"givenName"};
    $vorname=~s/ //g;
#    $nachname=umlautReplace($newMapWithUmlaut{"sn"});
#    $nachname=umlautTest($newMapWithUmlaut{"sn"});
    $nachname=$newMapWithUmlaut{"sn"};
    $nachname=~s/ //g;
    print LOG "vorname: >$vorname<\n";
    print LOG "nachname: >$nachname<\n";
    if ($vorname) {
        $cn ="$vorname $nachname";
#        $newMap{"cn"} = " $vorname $nachname";
        $newMap{"cn"} =umlautTest($cn);
    } else {
        #$newMap{"cn"} = " $nachname";
        $cn ="$nachname";
        $newMap{"cn"} =umlautTest($cn);
    }
    print "schreibe cn: >$cn<\n";

    write2Ldif(); 
   
    print LOG "#########################################\n";
}

close OUT || die "Kann Datei nicht schließen\n";
print LOG "end csv2ldif";
close LOG || die "Kann Datei nicht schließen\n";

sub write2Ldif {
    $dn=umlautTest("cn=$cn,ou=users,o=svens");
    print OUT "dn:$dn\n";
    print OUT "objectClass: top\nobjectClass: person\nobjectClass: organizationalPeople\nobjectClass: inetOrgPerson\n";
    foreach $indexKey (keys %newMap) {
        if ($newMap{$indexKey} =~/^(\ )$/){
        } else {
            print OUT "$indexKey:$newMap{$indexKey}\n";
        }
    }
    print OUT "\n";
}

sub umlautTest {
    print LOG "start umlautTest für: $_[0]\n";
    if ($_[0] =~ /[äÄüÜöÖ]/) {
        print LOG "$_[0] enthält Umlaute\n";
        $aa = $_[0];
        foreach $key (keys (%umlautMap)) {
            $aa =~ s/$key/$umlautMap{$key}/g;
            print LOG "Umlaut ersetzt: $key mit $umlautMap{$key} neuer name: $aa\n";
        }
        $encode=encode_base64(latin1($_[0]));
        chomp($encode);
        print LOG "encode: >$encode<\n";

        $decode = decode_base64($encode);
        print LOG "decode: >$decode<\n"; 
        return ": $encode";
    } else {
        print LOG "$_[0] enthält keine Umlaute\n";
        return " $_[0]";
    }
}

sub umlautReplace {
    print LOG "start umlautTest für: $_[0]\n";
    if ($_[0] =~ /[äÄüÜöÖ]/) {
        print LOG "$_[0] enthält Umlaute\n";
        $aa = $_[0];
        foreach $key (keys (%umlautMap)) {
            $aa =~ s/$key/$umlautMap{$key}/g;
            print LOG "Umlaut ersetzt: $key mit $umlautMap{$key} neuer name: $aa\n";
        }
        return " $aa";
    } else {
        print LOG "$_[0] enthält keine Umlaute\n";
        return " $_[0]";
    }
}

sub loadUmlautMap {
    open (UMLAUT,"<./umlaut.map") || die "Kann Datei nicht oeffnen\n" ;

    while (<UMLAUT>) {
        chomp;
        @umlaut=split(/,/,$_);
        print LOG "Umlaut: @umlaut\n";
        $umlautMap{$umlaut[0]}=$umlaut[1];
    }
    close(UMLAUT) || die "Kann Datei nicht schliessen";
    return %umlautMap;
}

sub loadKeyMap {
    open (KEYS,"<./keys.map") || die "Kann Datei nicht oeffnen\n" ;

    while (<KEYS>) {
        chomp;
        @keyMap=split(/,/,$_);
        print LOG "keys: @keyMap\n";
        $map{$keyMap[0]}=$keyMap[1];
    }
    close(KEYS) || die "Kann Datei nicht schliessen";
    return %map;
}

