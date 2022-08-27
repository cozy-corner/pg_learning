begin;

CREATE TABLE IF NOT EXISTS PWD(
    password VARCHAR(100) NOT NULL, -- 本来はパスワードを保存しない
    pwhash VARCHAR(100) NOT NULL -- パスワードと、ソルトから生成したハッシュ（ソルトを含む）
);

INSERT INTO PWD VALUES ('password', crypt('password', gen_salt('md5')));
SELECT * FROM PWD;
-- password,pwhash
-- password,$1$kJIAzygy$cNOxcT8n5TNZoZRM8RthT1

-- 認証
SELECT pwhash = crypt('password', pwhash) FROM PWD; -- return true
SELECT pwhash = crypt('bad password', pwhash) FROM PWD; -- return false

DROP TABLE PWD;

end;