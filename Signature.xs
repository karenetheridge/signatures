#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_parser
#include "ppport.h"

#include "hook_op_check.h"
#include "hook_parser.h"

typedef struct userdata_St {
	char *f_class;
	SV *class;
	hook_op_check_id parser_id;
} userdata_t;

STATIC void
call_to_perl (SV *class, UV offset, char *proto) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);
	EXTEND (SP, 3);
	PUSHs (class);
	mPUSHu (offset);
	mPUSHp (proto, strlen (proto));
	PUTBACK;

	call_method ("callback", G_VOID|G_DISCARD);

	FREETMPS;
	LEAVE;
}

STATIC SV *
qualify_func_name (const char *s) {
	SV *ret = newSVpvs ("");

	if (strstr (s, ":") == NULL) {
		sv_catpv (ret, SvPVX (PL_curstname));
		sv_catpvs (ret, "::");
	}

	sv_catpv (ret, s);

	return ret;
}

STATIC OP *
handle_proto (pTHX_ OP *op, void *user_data) {
	OP *ret;
	SV *op_sv, *name, *old_lex_stuff;
	char *s, *tmp, *tmp2;
	char tmpbuf[sizeof (PL_tokenbuf)], proto[sizeof (PL_tokenbuf)];
	STRLEN retlen = 0;
	userdata_t *ud = (userdata_t *)user_data;

	if (strNE (ud->f_class, SvPVX (PL_curstname))) {
		return op;
	}

	if (!PL_parser) {
		return op;
	}

	if (!PL_lex_stuff) {
		return op;
	}

	op_sv = cSVOPx (op)->op_sv;

	if (!SvPOK (op_sv)) {
		return op;
	}

	/* sub $name */
	s = PL_parser->oldbufptr;
	s = hook_toke_skipspace (aTHX_ s);

	if (strnNE (s, "sub", 3)) {
		return op;
	}

	if (!isSPACE (s[3])) {
		return op;
	}

	s = hook_toke_skipspace (aTHX_ s + 4);

	if (strNE (SvPVX (PL_subname), "?")) {
		(void)hook_toke_scan_word (aTHX_ (s - SvPVX (PL_linestr)), 1, tmpbuf, sizeof (tmpbuf), &retlen);

		if (!tmpbuf) {
			return op;
		}

		name = qualify_func_name (tmpbuf);

		if (!sv_eq (PL_subname, name)) {
			SvREFCNT_dec (name);
			return op;
		}

		SvREFCNT_dec (name);
	}

	/* ($proto) */
	s = hook_toke_skipspace (aTHX_ s + retlen);
	if (s[0] != '(') {
		return op;
	}

	tmp = hook_toke_scan_str (aTHX_ s);
	tmp2 = hook_parser_get_lex_stuff (aTHX);
	hook_parser_clear_lex_stuff (aTHX);

	if (s == tmp || !tmp2) {
		return op;
	}

	strncpy (proto, s + 1, tmp - s - 2);
	proto[tmp - s - 2] = '\0';

	s++;

	while (tmp > s + 1) {
		if (isSPACE (s[0])) {
			s++;
			continue;
		}

		if (*tmp2 != *s) {
			return op;
		}

		tmp2++;
		s++;
	}

	ret = NULL;

	s = hook_toke_skipspace (aTHX_ s + 1);
	if (s[0] == ':') {
		s++;
		while (s[0] != '{') {
			s = hook_toke_skipspace (aTHX_ s);
			char *attr_start = s;
			(void)hook_toke_scan_word (aTHX_ (s - SvPVX (PL_linestr)), 0, tmpbuf, sizeof (tmpbuf), &retlen);

			if (!tmpbuf) {
				return op;
			}

			s += retlen;
			if (s[0] == '(') {
				tmp = hook_toke_scan_str (aTHX_ s);
				tmp2 = hook_parser_get_lex_stuff (aTHX);
				hook_parser_clear_lex_stuff (aTHX);

				if (s == tmp) {
					return op;
				}

				s += strlen (tmp2);

				if (strEQ (tmpbuf, "proto")) {
					while (attr_start < tmp) {
						*attr_start = ' ';
						attr_start++;
					}

					ret = op;
					sv_setpv (op_sv, tmp2);
				}
			}
			else if (strEQ (tmpbuf, "proto")) {
				croak ("proto attribute requires argument");
			}

			s = hook_toke_skipspace(aTHX_ s);

            if (s[0] == ':') {
                s++;
            }
		}
	}

	if (s[0] != '{') {
		/* croak as we already messed with op when :proto is given? */
		return op;
	}

	call_to_perl (ud->class, s - hook_parser_get_linestr (aTHX), proto);

	if (!ret) {
		op_free (op);
	}

	return ret;
}

MODULE = Sub::Signature  PACKAGE = Sub::Signature

PROTOTYPES: DISABLE

UV
setup (class, f_class)
		SV *class
		char *f_class
	PREINIT:
		userdata_t *ud;
	INIT:
		Newx (ud, 1, userdata_t);
		ud->class = newSVsv (class);
		ud->f_class = f_class;
	CODE:
		ud->parser_id = hook_parser_setup ();
		RETVAL = (UV)hook_op_check (OP_CONST, handle_proto, ud);
	OUTPUT:
		RETVAL

void
teardown (class, id)
		UV id
	PREINIT:
		userdata_t *ud;
	CODE:
		ud = (userdata_t *)hook_op_check_remove (OP_CONST, id);

		if (ud) {
			hook_parser_teardown (ud->parser_id);
			SvREFCNT_dec (ud->class);
			Safefree (ud);
		}
