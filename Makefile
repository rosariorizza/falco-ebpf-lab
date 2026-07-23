.PHONY: doctor up up-tracefs logs shell list test verify validate down

doctor:
	./lab.sh doctor

up:
	./lab.sh up

up-tracefs:
	./lab.sh up-tracefs

logs:
	./lab.sh logs

shell:
	./lab.sh shell

list:
	./lab.sh list

test:
	./lab.sh test

verify:
	./lab.sh verify

validate:
	./lab.sh validate

down:
	./lab.sh down
