BEGIN  { FS = "," }
NR > 1 {
    print "dn: cn=dev "$1",dc=icp"
    print "uid: "$1
    print "cn: dev "$1
    print "sn: "$1
    print "objectClass: top"
    print "objectClass: inetOrgPerson"
    print "userPassword: "$2
    print ""
}
