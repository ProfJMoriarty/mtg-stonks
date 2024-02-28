# MTG Stonks

This is a stonks app for mtg cards. The product: A playability index, calculated for each card. The better its price / playability ratio, the higher its stonks.

# Setup

Dependencies:

- ruby 3.3.0 (rbenv)
- rails 7.1.3.2
- node 20.10.0 (nvm)
- postgresql 15

Setup commands:

Environment variables first:
```bash
cp .dotenv.example .env
```
Now fill in the blanks.

Database user next:
```bash
psql postgres
```
followed by
```sql
create user your_applciation_db_user_name_here with createdb login encrypted password 'your_application_db_pw_here';
```

and finally

```bash
rails db:prepare
```