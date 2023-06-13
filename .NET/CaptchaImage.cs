// @kkondaelatte
// Basic Captcha to be used as a placeholder on websites/desktop apps, saved in bmp.

using System;
using System.Drawing;
using System.IO;
using System.Linq;

public class CaptchaGenerator
{
    private static Random random = new Random();
    private string code;
    private Bitmap img;
    private const string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private const int maxLength = 8;

    public Bitmap GenerateCaptchaImage(int width, int height)
    {
        img = new Bitmap(width, height);

        using (Graphics graphics = Graphics.FromImage(img))
        {
            graphics.Clear(Color.Black);

            code = GenerateRandomCode();

            Font font = new Font("Arial", height / 2);
            SolidBrush brush = new SolidBrush(Color.White);

            for (int i = 0; i < code.Length; i++)
            {
                graphics.DrawString(code[i].ToString(), font, brush, i * width / code.Length, height / 2);
            }
        }

        // do some magic
        img = AddNoise(AddDistortion(img, 10), 5000);

        return img;
    }

    private string GenerateRandomCode()
    {
        int length = random.Next(1, maxLength + 1);
        string randomCode = new string(Enumerable.Repeat(chars, length)
          .Select(s => s[random.Next(s.Length)]).ToArray());

        return randomCode;
    }

    public bool ValidateCaptcha(string userInput)
    {
        return string.Equals(userInput, code, StringComparison.OrdinalIgnoreCase); //case insensitive for dev
    }

    public void SaveImage(string path)
    {
        captchaImage.Save(path);
    }

    private Bitmap AddDistortion(Bitmap source, int degree)
    {
        Bitmap dest = new Bitmap(source.Width, source.Height);


        // some sinusoidal disortion
        for (int y = 0; y < source.Height; y++)
        {
            for (int x = 0; x < source.Width; x++)
            {
                int newX = (int)(x + (degree * Math.Sin(Math.PI * y / 64.0)));
                int newY = (int)(y + (degree * Math.Cos(Math.PI * x / 64.0)));
                if (newX < 0 || newX >= source.Width) newX = 0;
                if (newY < 0 || newY >= source.Height) newY = 0;
                dest.SetPixel(x, y, source.GetPixel(newX, newY));
            }
        }

        return dest;
    }

    private Bitmap AddNoise(Bitmap src, int density)
    {
        for (int y = 0; y < src.Height; y++)
        {
            for (int x = 0; x < src.Width; x++)
            {
                if (random.Next() % density == 0)
                {
                    int alpha = random.Next(50, 100);
                    Color color = Color.FromArgb(alpha, Color.White);
                    src.SetPixel(x, y, color);
                }
            }
        }

        return src;
    }
}
