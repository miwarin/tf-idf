#!/usr/bin/ruby -Ku

# TF-IDF を求める
#
# [を] 形態素解析と検索APIとTF-IDFでキーワード抽出 http://chalow.net/2005-10-12-1.html
#
#

require 'pp'


# 形態素解析
def analysis(inputfile)
#  mecab_cmd = '/cygdrive/c/Program\ Files/MeCab/bin/mecab.exe'
  mecab_cmd =  '/cygdrive/c/Program\ Files\ \(x86\)/MeCab/bin/mecab.exe'
  text = `#{mecab_cmd} -b 81920 #{inputfile}`

  words = []
  lines = text.split(/\r\n/)
  lines.grep(/固有名詞/) {|line|
    words << line.split("\t")[0]
  }

  return words

end

# キーワード抽出対象テキスト中の代表キーワード候補出現数 (TF)
def getTF(inputdir)

  tf = {}
  tf.default = 0
  n = 0
  
  Dir.glob("#{inputdir}/*.td2").each {|e|
    next unless FileTest.file?(e)
    
    n += 1

    words = analysis(e)
    words.each {|word|
      tf[word] += 1
    }

  }
  
  return tf, n
end


def getDF(inputdir, tf)

  df = {}
  df.default = 0
  
  Dir.glob("#{inputdir}/*.td2").each {|e|
    next unless FileTest.file?(e)
    
    tf.each {|word, count|
      count = getCount(word, e)
      df[word] += count
    }
  }
  
  return df
  
end



# 代表キーワード候補が含まれるドキュメントの数 (DF)
def getCount(word, inputfile)
  text = File.open(inputfile).read()
  hit = text.include?(word) ? 1 : 0
  return hit
end


def tf_idf(inputdir)

  tf, n = getTF(inputdir)
  
  df = getDF(inputdir, tf)
  
  tfidf ||= {}
  tfidf.default = 0

  df.each {|word, count|
    i = tf[word] * Math.log(n / df[word])
    tfidf[word] = i
  }
  
  return tfidf

end

def tag_cloud(contents, outfile)
  require 'cloud'
  tagcloud_html = tagcloud(contents)
  out_html = html(tagcloud_html)
  output(outfile, out_html)
end

def main(argv)
  indir = argv[0]
  outfile = argv[1]
  
  tfidf = tf_idf(indir)
  
  tfidf.reject! {|w, c|
    c <= 0
  }
  
  ts =  tfidf.to_a.sort {|a, b|
    b[1] <=> a[1]
  }
  
  ts.each {|w, c|
    puts "#{w} #{c}"
  }

  tag_cloud(tfidf, outfile)


end

main(ARGV)
